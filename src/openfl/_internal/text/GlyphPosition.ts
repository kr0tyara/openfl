namespace openfl._internal.text;

#if lime
import lime.math.Vector2;
import lime.text.Glyph;

#if!openfl_debug
@: fileXml('tags="haxe,release"')
@: noDebug
#end
@SuppressWarnings(["checkstyle:FieldDocComment", "checkstyle:Dynamic"])
class GlyphPosition
{
	public advance: Vector2;
	public glyph: Glyph;
	public offset: Vector2;

	public constructor(glyph: Glyph, advance: Vector2, offset: Vector2 = null)
	{
		this.glyph = glyph;
		this.advance = advance;

		if (offset != null)
		{
			this.offset = offset;
		}
		else
		{
			this.offset = #if lime new Vector2() #else { } #end;
		}
	}
}
#end