page 468 "Tax Details"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Details';
    DataCaptionFields = "Tax Jurisdiction Code", "Tax Group Code";
    PageType = List;
    SourceTable = "Tax Detail";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tax Jurisdiction Code"; "Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax jurisdiction code for the tax-detail entry.';
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';
                }
                field("Tax Type"; "Tax Type")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the type of tax (Sales Tax or Excise Tax) that applies to the tax-detail entry.';
                }
                field("Effective Date"; "Effective Date")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a date on which the tax-detail entry will go into effect. This allows you to set up tax details in advance.';
                }
                field("Tax Below Maximum"; "Tax Below Maximum")
                {
                    ApplicationArea = SalesTax;
                    MinValue = 0;
                    ToolTip = 'Specifies the percentage that will be used to calculate tax for all amounts or quantities below the maximum amount quantity in the Maximum Amount/Qty. field.';
                }
                field("Maximum Amount/Qty."; "Maximum Amount/Qty.")
                {
                    ApplicationArea = SalesTax;
                    MinValue = 0;
                    ToolTip = 'Specifies a maximum amount or quantity. The program finds the appropriate tax percentage in either the Tax Below Maximum or the Tax Above Maximum field.';
                }
                field("Tax Above Maximum"; "Tax Above Maximum")
                {
                    ApplicationArea = SalesTax;
                    MinValue = 0;
                    ToolTip = 'Specifies the percentage that will be used to calculate tax for all amounts or quantities above the maximum amount quantity in the Maximum Amount/Qty. field.';
                }
                field("Expense/Capitalize"; "Expense/Capitalize")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if you want to expense or capitalize unrecoverable taxes that have been paid on purchases. The tax amount will be expensed or capitalized to the purchase debit account based on the value in the Type field on the purchase order lines. The debit will impact the purchase account (inventory), asset acquisition account (fixed asset), or other expense accounts (general ledger). The amount payable to the vendor will include the additional liability for the sales tax being charged. Therefore, when the vendor is paid for the accounts payable balance, the amount will include the amount of the goods in addition to the amount of the tax on those goods.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Detail")
            {
                Caption = '&Detail';
                Image = View;
                action("Ledger &Entries")
                {
                    ApplicationArea = SalesTax;
                    Caption = 'Ledger &Entries';
                    Image = VATLedger;
                    Promoted = false;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View Tax entries, which result from posting transactions in journals and sales and purchase documents, and from the Calc. and Post Tax Settlement batch job.';

                    trigger OnAction()
                    var
                        VATEntry: Record "VAT Entry";
                    begin
                        VATEntry.SetCurrentKey("Tax Jurisdiction Code", "Tax Group Used", "Tax Type", "Use Tax", "Posting Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                        VATEntry.SetRange("Tax Group Used", "Tax Group Code");
                        VATEntry.SetRange("Tax Type", "Tax Type");
                        PAGE.Run(PAGE::"VAT Entries", VATEntry);
                    end;
                }
            }
        }
    }
}

