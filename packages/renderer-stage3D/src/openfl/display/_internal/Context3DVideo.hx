package openfl.display._internal;

#if openfl_gl
import lime.graphics.opengl.GL;
import lime.utils.Float32Array;
import lime.utils.UInt16Array;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display._Context3DRenderer;
import openfl.media.Video;
import openfl.media._Video;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display3D._Context3D) // TODO: Remove backend references
@:access(openfl.display3D.textures._TextureBase)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.Shader)
@:access(openfl.geom.ColorTransform)
@:access(openfl.media.Video)
@:access(openfl.net.NetStream)
@SuppressWarnings("checkstyle:FieldDocComment")
class Context3DVideo
{
	public static inline var VERTEX_BUFFER_STRIDE:Int = 5;

	public static var __textureSizeValue:Array<Float> = [0, 0.];

	public static function getIndexBuffer(video:Video, context:Context3D):IndexBuffer3D
	{
		#if (lime && openfl_gl)
		if ((video._ : _Video).__renderData.indexBuffer == null || (video._ : _Video).__renderData.indexBufferContext != context)
		{
			// TODO: Use shared buffer on context

			(video._ : _Video).__renderData.indexBufferData = new UInt16Array(6);
			(video._ : _Video).__renderData.indexBufferData[0] = 0;
			(video._ : _Video).__renderData.indexBufferData[1] = 1;
			(video._ : _Video).__renderData.indexBufferData[2] = 2;
			(video._ : _Video).__renderData.indexBufferData[3] = 2;
			(video._ : _Video).__renderData.indexBufferData[4] = 1;
			(video._ : _Video).__renderData.indexBufferData[5] = 3;

			(video._ : _Video).__renderData.indexBufferContext = context;
			(video._ : _Video).__renderData.indexBuffer = context.createIndexBuffer(6);
			(video._ : _Video).__renderData.indexBuffer.uploadFromTypedArray((video._ : _Video).__renderData.indexBufferData);
		}

		return (video._ : _Video).__renderData.indexBuffer;
		#else
		return null;
		#end
	}

	public static function getTexture(video:Video, context:Context3D):RectangleTexture
	{
		#if openfl_html5
		if ((video._ : _Video).__stream == null) return null;

		var videoElement = (video._ : _Video).__stream._.__getVideoElement();
		if (videoElement == null) return null;

		var gl = context._.gl;
		var internalFormat = GL.RGBA;
		var format = GL.RGBA;

		if (!(video._ : _Video).__stream._.__closed && videoElement.currentTime != (video._ : _Video).__renderData.textureTime)
		{
			if ((video._ : _Video).__renderData.texture == null)
			{
				(video._ : _Video).__renderData.texture = context.createRectangleTexture(videoElement.videoWidth, videoElement.videoHeight, BGRA, false);
			}

			context._.bindGLTexture2D((video._ : _Video).__renderData.texture._.__base.glTextureID);
			gl.texImage2D(GL.TEXTURE_2D, 0, internalFormat, format, GL.UNSIGNED_BYTE, videoElement);

			(video._ : _Video).__renderData.textureTime = videoElement.currentTime;
		}

		return cast(video._ : _Video).__renderData.texture;
		#else
		return null;
		#end
	}

	public static function getVertexBuffer(video:Video, context:Context3D):VertexBuffer3D
	{
		#if (lime && openfl_gl)
		if ((video._ : _Video).__renderData.vertexBuffer == null || (video._ : _Video).__renderData.vertexBufferContext != context)
		{
			#if openfl_power_of_two
			var newWidth = 1;
			var newHeight = 1;

			while (newWidth < width)
			{
				newWidth <<= 1;
			}

			while (newHeight < height)
			{
				newHeight <<= 1;
			}

			var uvWidth = width / newWidth;
			var uvHeight = height / newHeight;
			#else
			var uvWidth = 1;
			var uvHeight = 1;
			#end

			(video._ : _Video).__renderData.vertexBufferData = new Float32Array(VERTEX_BUFFER_STRIDE * 4);

			(video._ : _Video).__renderData.vertexBufferData[0] = video.width;
			(video._ : _Video).__renderData.vertexBufferData[1] = video.height;
			(video._ : _Video).__renderData.vertexBufferData[3] = uvWidth;
			(video._ : _Video).__renderData.vertexBufferData[4] = uvHeight;
			(video._ : _Video).__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE + 1] = video.height;
			(video._ : _Video).__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE + 4] = uvHeight;
			(video._ : _Video).__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE * 2] = video.width;
			(video._ : _Video).__renderData.vertexBufferData[VERTEX_BUFFER_STRIDE * 2 + 3] = uvWidth;

			(video._ : _Video).__renderData.vertexBufferContext = context;
			(video._ : _Video).__renderData.vertexBuffer = context.createVertexBuffer(3, VERTEX_BUFFER_STRIDE);
			(video._ : _Video).__renderData.vertexBuffer.uploadFromTypedArray((video._ : _Video).__renderData.vertexBufferData);
		}

		return (video._ : _Video).__renderData.vertexBuffer;
		#else
		return null;
		#end
	}

	public static function render(video:Video, renderer:OpenGLRenderer):Void
	{
		#if openfl_html5
		if (!(video._ : _Video).__renderable || (video._ : _Video).__worldAlpha <= 0 || (video._ : _Video).__stream == null) return;

		var videoElement = (video._ : _Video).__stream._.__getVideoElement();

		if (videoElement != null)
		{
			var context = (renderer._ : _Context3DRenderer).context3D;
			var gl = context._.gl;

			var texture = getTexture(video, context);
			if (texture == null) return;

			(renderer._ : _Context3DRenderer).__setBlendMode((video._ : _Video).__worldBlendMode);
			(renderer._ : _Context3DRenderer).__pushMaskObject(video);
			// renderer.filterManager.pushObject (video);

			var shader = (renderer._ : _Context3DRenderer).__initDisplayShader(cast(video._ : _Video).__worldShader);
			renderer.setShader(shader);

			// TODO: Support ShaderInput<Video>
			renderer.applyBitmapData(null, true, false);
			// context._.__bindGLTexture2D (getTexture(video, context));
			// shader.uImage0.input = bitmap._.__bitmapData;
			// shader.uImage0.smoothing = (renderer._ : _Context3DRenderer).__allowSmoothing && (bitmap.smoothing || (renderer._ : _Context3DRenderer).__upscaled);
			renderer.applyMatrix((renderer._ : _Context3DRenderer).__getMatrix((video._ : _Video).__renderTransform, AUTO));
			renderer.applyAlpha((renderer._ : _Context3DRenderer).__getAlpha((video._ : _Video).__worldAlpha));
			renderer.applyColorTransform((video._ : _Video).__worldColorTransform);

			if (shader._.__textureSize != null)
			{
				__textureSizeValue[0] = ((video._ : _Video).__stream != null) ? videoElement.videoWidth : 0;
				__textureSizeValue[1] = ((video._ : _Video).__stream != null) ? videoElement.videoHeight : 0;
				shader._.__textureSize.value = __textureSizeValue;
			}

			renderer.updateShader();

			context.setTextureAt(0, getTexture(video, context));
			context._.flushGLTextures();
			gl.uniform1i(shader._.__texture.index, 0);

			if (video.smoothing)
			{
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
			}
			else
			{
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
				gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
			}

			var vertexBuffer = getVertexBuffer(video, context);
			if (shader._.__position != null) context.setVertexBufferAt(shader._.__position.index, vertexBuffer, 0, FLOAT_3);
			if (shader._.__textureCoord != null) context.setVertexBufferAt(shader._.__textureCoord.index, vertexBuffer, 3, FLOAT_2);
			var indexBuffer = getIndexBuffer(video, context);
			context.drawTriangles(indexBuffer);

			#if gl_stats
			Context3DStats.incrementDrawCall(DrawCallContext.STAGE);
			#end

			(renderer._ : _Context3DRenderer).__clearShader();

			// renderer.filterManager.popObject (video);
			(renderer._ : _Context3DRenderer).__popMaskObject(video);
		}
		#end
	}

	public static function renderMask(video:Video, renderer:OpenGLRenderer):Void
	{
		#if openfl_html5
		if ((video._ : _Video).__stream == null) return;

		if ((video._ : _Video).__stream._.__getVideoElement() != null)
		{
			var context = (renderer._ : _Context3DRenderer).context3D;

			var shader = (renderer._ : _Context3DRenderer).__maskShader;
			renderer.setShader(shader);
			renderer.applyBitmapData(Context3DMaskShader.opaqueBitmapData, true);
			renderer.applyMatrix((renderer._ : _Context3DRenderer).__getMatrix((video._ : _Video).__renderTransform, AUTO));
			renderer.updateShader();

			var vertexBuffer = getVertexBuffer(video, context);
			if (shader._.__position != null) context.setVertexBufferAt(shader._.__position.index, vertexBuffer, 0, FLOAT_3);
			if (shader._.__textureCoord != null) context.setVertexBufferAt(shader._.__textureCoord.index, vertexBuffer, 3, FLOAT_2);
			var indexBuffer = getIndexBuffer(video, context);
			context.drawTriangles(indexBuffer);

			#if gl_stats
			Context3DStats.incrementDrawCall(DrawCallContext.STAGE);
			#end

			(renderer._ : _Context3DRenderer).__clearShader();
		}
		#end
	}
}
#end
