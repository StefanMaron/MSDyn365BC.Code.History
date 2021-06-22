page 968 "Time Sheet Line Assemb. Detail"
{
    Caption = 'Time Sheet Line Assemb. Detail';
    Editable = false;
    PageType = StandardDialog;
    SourceTable = "Time Sheet Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Assembly Order No."; "Assembly Order No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the assembly order number that is associated with the time sheet line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the time sheet line.';
                }
                field(Chargeable; Chargeable)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the usage that you are posting is chargeable.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SetParameters(TimeSheetLine: Record "Time Sheet Line")
    begin
        Rec := TimeSheetLine;
        Insert;
    end;
}

