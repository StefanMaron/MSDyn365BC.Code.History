page 12413 "VAT Sales Ledger Subform"
{
    Caption = 'VAT Sales Ledger';
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "VAT Ledger Line" = rm;
    SourceTable = "VAT Ledger Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the line.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Real. VAT Entry Date"; "Real. VAT Entry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date of the realized VAT associated with this VAT ledger line.';
                }
                field("Unreal. VAT Entry Date"; "Unreal. VAT Entry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date of the unrealized VAT associated with this VAT ledger line.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("C/V No."; "C/V No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor number associated with this VAT ledger line.';
                }
                field("C/V Name"; "C/V Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor name associated with this VAT ledger line.';
                }
                field("C/V VAT Reg. No."; "C/V VAT Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor VAT registration number associated with this VAT ledger line.';
                }
                field("Reg. Reason Code"; "Reg. Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the regular reason code associated with this VAT ledger line.';
                }
                field(Method; Method)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method associated with this VAT ledger line.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, including VAT, of this VAT ledger line.';
                }
                field(Base18; Base18)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for an 18 percent VAT rate.';
                }
                field(Amount18; Amount18)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount for an 18 percent VAT rate.';
                }
                field(Base20; Base20)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for a 20 percent VAT rate.';
                }
                field(Amount20; Amount20)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount for a 20 percent VAT rate.';
                }
                field(Base10; Base10)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for a 10 percent VAT rate.';
                }
                field(Amount10; Amount10)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax amount for a 10 percent VAT rate.';
                }
                field(Base0; Base0)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT amount for a zero percent VAT rate.';
                }
                field("Base VAT Exempt"; "Base VAT Exempt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base VAT exempt amount of this VAT ledger line.';
                }
                field("Sales Tax Base"; "Sales Tax Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales tax base associated with this VAT ledger line.';
                }
                field("Sales Tax Amount"; "Sales Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales tax amount associated with this VAT ledger line.';
                }
                field("Full Sales Tax Amount"; "Full Sales Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full sales tax amount associated with this VAT ledger line.';
                }
                field("CD No."; "CD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
                }
                field(Prepayment; Prepayment)
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the related payment is a prepayment.';
                }
                field("Amt. Diff. VAT"; "Amt. Diff. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this VAT ledger line has an amount difference.';
                }
                field("No. of Purch. Ledger Lines"; "No. of Purch. Ledger Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of purchase ledger lines that are associated with this VAT ledger line.';
                }
                field("No. of VAT Sales Entries"; "No. of VAT Sales Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of VAT sales entries of this VAT ledger line.';
                }
                field("Additional Sheet"; "Additional Sheet")
                {
                    ToolTip = 'Specifies if this VAT ledger line has an additional sheet.';
                    Visible = false;
                }
                field("Corr. VAT Entry Posting Date"; "Corr. VAT Entry Posting Date")
                {
                    ToolTip = 'Specifies the posting date of the corrected VAT entry.';
                    Visible = false;
                }
                field("VAT Entry Type"; "VAT Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "VAT Entry Type".Code;
                    ToolTip = 'Specifies a VAT entry code according to Russian legislation. Some types of documents, such as corrective or revision invoices, must have multiple VAT entry type codes.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord
                    end;
                }
                field("Tariff No."; "Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item tariff number that is associated with this VAT ledger line.';
                }
            }
        }
    }

    actions
    {
    }

    var
        Navigate: Page Navigate;

    [Scope('OnPrem')]
    procedure NavigateDocument()
    begin
        Navigate.SetDoc("Document Date", "Document No.");
        Navigate.Run;
    end;
}

