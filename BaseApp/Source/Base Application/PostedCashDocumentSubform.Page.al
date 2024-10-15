page 11736 "Posted Cash Document Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    PageType = ListPart;
    SourceTable = "Posted Cash Document Line";

    layout
    {
        area(content)
        {
            repeater(Control1220025)
            {
                ShowCaption = false;
                field("Cash Desk Event"; "Cash Desk Event")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cash desk event in the cash document lines.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash desk document type is payment or refund.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the vendor uses on the invoice they sent to you or number of receipt.';
                    Visible = false;
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account thet the entry will be posted to. To see the options, choose the field.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry on the journal line will be posted to.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of cash document line.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the another line for description if description is longer.';
                    Visible = false;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the general posting type is purchase (Purchase) or sale (Sale).';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT business posting group code.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount that the cash document line consists of.';
                }
                field("VAT Base Amount"; "VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total VAT base amount for lines. The program calculates this amount from the sum of line VAT base amount fields.';
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount for cash desk document line.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code of the Shortcut Dimension 1, which is defined in the Shortcut Dimension 1 Code field in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code of the Shortcut Dimension 2, which is defined in the Shortcut Dimension 2 Code field in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which salesperson/purchaser is assigned to the cash desk document.';
                }
                field("Applies-To Doc. Type"; "Applies-To Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment will be applied to an already-posted document. The field is used only if the account type is a customer or vendor account.';
                }
                field("Applies-To Doc. No."; "Applies-To Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash document line will be applied to an already-posted document.';
                }
                field("EET Transaction"; "EET Transaction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the value of Yes will automatically be filled when the row meets the conditions for a recorded sale.';
                    Visible = false;
                }
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                    Visible = false;
                }
                field("FA Posting Type"; "FA Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = ' ,Acquisition Cost,,,,,Custom 2,,Maintenance';
                    ToolTip = 'Specifies if the cash document line amount represents a acquisition cost (Acquisition Cost) or a depreciation (Depreciation) or a write down (Write-Down) or an appreciation (Appreciation) or a custom 1 (Custom 1) or a custom 2 (Custom 2) or a disposal (Disposal) or a maintenance (Maintenance).';
                    Visible = false;
                }
                field("Duplicate in Depreciation Book"; "Duplicate in Depreciation Book")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you have selected Fixed Asset in the Account Type field for this line.';
                    Visible = false;
                }
                field("Use Duplication List"; "Use Duplication List")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you have selected Fixed Asset in the Account Type field for this line.';
                    Visible = false;
                }
                field("Maintenance Code"; "Maintenance Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a maintenance code.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code on the entry.';
                    Visible = false;
                }
            }
            group(Control1220034)
            {
                ShowCaption = false;
                field("TotalPostedCashDocumentHeader.""VAT Base Amount"""; TotalPostedCashDocumentHeader."VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = TotalPostedCashDocumentHeader."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalExclVATCaption(TotalPostedCashDocumentHeader."Currency Code");
                    Caption = 'Total Amount Excl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amout excl. VAT.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = TotalPostedCashDocumentHeader."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalVATCaption(TotalPostedCashDocumentHeader."Currency Code");
                    Caption = 'Total VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amout of VAT.';
                }
                field("TotalPostedCashDocumentHeader.""Amount Including VAT"""; TotalPostedCashDocumentHeader."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = TotalPostedCashDocumentHeader."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalInclVATCaption(TotalPostedCashDocumentHeader."Currency Code");
                    Caption = 'Total Amount Incl. VAT';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the total amout incl. VAT.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected cash document.';

                    trigger OnAction()
                    begin
                        ExtStatistics;
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View the dimension sets that are set up for the cash document.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocumentTotals.CalculatePostedCashDocumentTotals(TotalPostedCashDocumentHeader, VATAmount, Rec);
    end;

    var
        TotalPostedCashDocumentHeader: Record "Posted Cash Document Header";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
}

