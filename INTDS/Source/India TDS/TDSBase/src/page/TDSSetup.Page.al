page 18696 "TDS Setup"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "TDS Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Tax Type"; "Tax Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the tax type. Tax type can be TDS, TCS and GST.';
                }
                field("TDS Nil Challan Nos."; "TDS Nil Challan Nos.")
                {
                    Caption = 'TDS Nil Challan Nos.';
                    ToolTip = 'Specifies the code linked to entries that are posted from a challan register.';
                    ApplicationArea = Basic, Suite;
                }
                field("Nil Pay TDS Document Nos."; "Nil Pay TDS Document Nos.")
                {
                    Caption = 'Nil Pay TDS Document Nos.';
                    ToolTip = 'Specifies the code linked to entries that are posted from a challan register.';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Reset();
        if not Get() THEN begin
            Init();
            Insert();
        end;
    end;
}