module Sheet
  class << self
    def red
      Google::Apis::SheetsV4::Color.new(COLOURS[:red])
    end

    def green
      Google::Apis::SheetsV4::Color.new(COLOURS[:green])
    end

    def blue
      Google::Apis::SheetsV4::Color.new(COLOURS[:blue])
    end

    def red_dark
      Google::Apis::SheetsV4::Color.new(COLOURS[:red_dark])
    end

    def green_dark
      Google::Apis::SheetsV4::Color.new(COLOURS[:green_dark])
    end

    def blue_dark
      Google::Apis::SheetsV4::Color.new(COLOURS[:blue_dark])
    end

    def white
      Google::Apis::SheetsV4::Color.new(COLOURS[:white])
    end

    def black
      Google::Apis::SheetsV4::Color.new(COLOURS[:black])
    end

    def text_format_red
      Google::Apis::SheetsV4::TextFormat.new(bold: false, foreground_color: red_dark)
    end

    def text_format_green
      Google::Apis::SheetsV4::TextFormat.new(bold: false, foreground_color: green_dark)
    end

    def text_format_blue
      Google::Apis::SheetsV4::TextFormat.new(bold: true, foreground_color: blue_dark)
    end

    def text_format_black
      Google::Apis::SheetsV4::TextFormat.new(bold: false, foreground_color: black)
    end

    def cell_format_red
      Google::Apis::SheetsV4::CellFormat.new(background_color: red, text_format: text_format_black, horizontal_alignment: 'center')
    end

    def cell_format_green
      Google::Apis::SheetsV4::CellFormat.new(background_color: green, text_format: text_format_black, horizontal_alignment: 'center')
    end

    def cell_format_blue
      Google::Apis::SheetsV4::CellFormat.new(background_color: blue, text_format: text_format_blue, horizontal_alignment: 'center')
    end

    def cell_format_white
      Google::Apis::SheetsV4::CellFormat.new(background_color: white, text_format: text_format_black, horizontal_alignment: 'center')
    end

    def cell_format_white_right
      Google::Apis::SheetsV4::CellFormat.new(background_color: white, text_format: text_format_black, horizontal_alignment: 'right')
    end

    def cell_data_red
      Google::Apis::SheetsV4::CellData.new(user_entered_format: cell_format_red)
    end

    def cell_data_green
      Google::Apis::SheetsV4::CellData.new(user_entered_format: cell_format_green)
    end

    def cell_data_blue
      Google::Apis::SheetsV4::CellData.new(user_entered_format: cell_format_blue)
    end

    def cell_data_white
      Google::Apis::SheetsV4::CellData.new(user_entered_format: cell_format_white)
    end
  end
end
