page 349 "VAT Reporting Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Reporting Codes';
    PageType = List;
    SourceTable = "VAT Reporting Code";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(VATCodes)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT reporting code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the VAT reporting code.';
                }
            }
        }
    }
}
