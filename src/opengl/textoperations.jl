using Visualize: glyph_advance!, glyph_bearing!, glyph_uv_width!, glyph_scale!

isnewline(x) = x == '\n'

type Text
    data
    text
    atlas
    cursors
    # default values
    font
    scale
    offset
    color
    startposition
    lineheight
end


function nextposition(sprite::Sprite, char, text)
    advance_x, advance_y = glyph_advance!(text.atlas, char, text.font, text.scale)
    position = sprite.position
    if isnewline(char)
        return Point2f0(text.startposition[1], position[2] - advance_y * text.lineheight) #reset to startx
    else
        return position + Point2f0(advance_x, 0)
    end
end

function printat(text::Text, idx::Integer, char::Char)
    position = if checkbounds(Bool, text.data, idx)
        sprite = text.data[idx]
        nextposition(sprite, text.text[idx], text)
    else
        text.startposition
    end
    nextsprite = Sprite(char, position, text)
    idx += 1
    insert!(text.data, idx, nextsprite)
    insert!(text.text, idx, char)
    idx
end
function printat(text::Text, idx::Int, str::String)
    sprite = text.data[idx]
    position = sprite.position
    for char in str
        char == '\r' && continue # stupid windows!
        idx = printat(text, idx, char)
    end
    idx
end

function Base.print(text::Text, char::Union{Char, String})
    map!(text.cursors, text.cursors) do idx
        idx = printat(text, idx, char)
        return idx
    end
    nothing
end
Base.String(text::Text) = join(text.text)
