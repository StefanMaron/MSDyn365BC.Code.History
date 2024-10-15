page 11602 "BAS Calc. Schedule Fields"
{
    Caption = 'BAS Calc. Schedule Fields';
    Editable = false;
    PageType = List;
    SourceTable = "Field";
    SourceTableView = WHERE(TableNo = FILTER(11601),
                            "No." = FILTER(< 100));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the document.';
                }
                field(FieldName; FieldName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    ToolTip = 'Specifies the name of the field.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NoOnFormat();
        FieldNameOnFormat();
        FieldCaptionOnFormat();
    end;

    var
        BASManagement: Codeunit "BAS Management";

    local procedure NoOnFormat()
    begin
        // CurrForm."No.".UPDATEFONTBOLD(BASManagement.CheckBASFieldID("No.",FALSE)); Commented due to build 28171
        BASManagement.CheckBASFieldID("No.", false);
    end;

    local procedure FieldNameOnFormat()
    begin
        // CurrForm.FieldName.UPDATEFONTBOLD(BASManagement.CheckBASFieldID("No.",FALSE));
        BASManagement.CheckBASFieldID("No.", false)
    end;

    local procedure FieldCaptionOnFormat()
    begin
        // CurrForm."Field Caption".UPDATEFONTBOLD(BASManagement.CheckBASFieldID("No.",FALSE));
        BASManagement.CheckBASFieldID("No.", false)
    end;
}

