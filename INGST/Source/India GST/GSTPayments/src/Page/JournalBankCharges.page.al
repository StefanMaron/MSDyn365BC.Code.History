page 18247 "Journal Bank Charges"
{
    PageType = list;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Journal Bank Charges";
    DataCaptionFields = "Bank Charge";
    Caption = 'Journal Bank Charges';
    DelayedInsert = true;

    layout
    {
        area(FactBoxes)
        {
            part(TaxInformation; "Tax Information Factbox")
            {
                ApplicationArea = all;
                SubPageLink = "Table ID Filter" = const(18247),
                    "Template Name Filter" = field("Journal Template Name"),
                    "Batch Name Filter" = field("Journal Batch Name"),
                    "Line No. Filter" = field("Line No.");
            }

        }
        area(Content)
        {
            repeater(GroupName)
            {
                field("Bank Charge"; Rec."Bank Charge")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank charge code.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank charge amount of the journal line.';
                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the Customer/Vendors/Banks numbering system.';
                }
                field(Exempted; Rec.Exempted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the journal is exempted from GST.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in local currency as defined in company information.';
                }
                field("Foreign Exchange"; Rec."Foreign Exchange")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction has a foreign currency involved.';
                }
                field("GST Document Type"; Rec."GST Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST Document Type of the journal.';
                }
                field(LCY; Rec.LCY)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction is in local currency.';
                }
            }
        }
    }
}
