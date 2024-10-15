page 18694 "TDS Section Card"
{
    PageType = Card;
    SourceTable = "TDS Section";
    Caption = 'TDS Section';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the section codes under which tax has been deducted.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the description of nature of payment.';
                }
                field(ecode; ecode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'eTDS';
                    ToolTip = 'Specify the section code to be used in the return.';
                }
            }
        }
    }
}