#if not CLEAN17
page 11735 "Posted Cash Document"
{
    Caption = 'Posted Cash Document (Obsolete)';
    Editable = false;
    PageType = Document;
    SourceTable = "Posted Cash Document Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Cash Desk No."; "Cash Desk No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of cash desk.';
                }
                field("Cash Document Type"; "Cash Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash desk document represents a cash receipt (Receipt) or a withdrawal (Wirthdrawal)';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash document.';
                }
                field("Payment Purpose"; "Payment Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payment purpose.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the cash document was posted.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("Amounts Including VAT"; "Amounts Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Received From"; "Received From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who recieved amount.';
                }
                field("Paid To"; "Paid To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whom is paid.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            "Currency Factor" := ChangeExchangeRate.GetParameter;
                            Modify;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("VAT Base Amount"; "VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total VAT base amount for lines. The program calculates this amount from the sum of line VAT base amount fields.';
                    Visible = false;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
                field("VAT Base Amount (LCY)"; "VAT Base Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the VAT base amount for cash desk document line.';
                    Visible = false;
                }
                field("Amount Including VAT (LCY)"; "Amount Including VAT (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
            }
            part(PostedCashDocLines; "Posted Cash Document Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Cash Desk No." = FIELD("Cash Desk No."),
                              "Cash Document No." = FIELD("No.");
                SubPageView = SORTING("Cash Desk No.", "Cash Document No.", "Line No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the partner is Customer or Vendor or Contact or Salesperson/Purchaser or Employee.';
                }
                field("Partner No."; "Partner No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the partner number.';
                }
                field("Received By"; "Received By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who recieved amount.';
                }
                field("Paid By"; "Paid By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whom is paid.';
                }
                field("Identification Card No."; "Identification Card No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for a card.';
                }
                field("Registration No."; "Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number of customer or vendor.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the Shortcut Dimension 1, which is defined in the Shortcut Dimension 1 Code field in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the Shortcut Dimension 2, which is defined in the Shortcut Dimension 2 Code field in the General Ledger Setup window.';
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which salesperson/purchaser is assigned to the cash desk document.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the responsibility center which works with this cash desk.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the vendor uses on the invoice they sent to you or number of receipt.';
                }
                field("EET Entry No."; "EET Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the EET entry number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
                    ObsoleteTag = '18.0';
                }
                field("Receipt Serial No."; "Receipt Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the serial no. of the EET receipt.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
                    ObsoleteTag = '18.0';
                }
                field("Created ID"; "Created ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies employee ID of creating cash desk document.';
                }
                field("Created Date"; "Created Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies date of creating cash desk document.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Dimensions';
                Image = Dimensions;
                ToolTip = 'View the dimension sets that are set up for the cash document.';

                trigger OnAction()
                begin
                    ShowDimensions();
                end;
            }
            action("EET Entry")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'EET Entry';
                Image = Entry;
                ToolTip = 'Shows a card of the recorded sale entry.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
                ObsoleteTag = '18.0';

                trigger OnAction()
                begin
                    ShowEETEntry;
                end;
            }
        }
        area(reporting)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PostedCashDocHeader: Record "Posted Cash Document Header";
                begin
                    PostedCashDocHeader := Rec;
                    PostedCashDocHeader.SetRecFilter;
                    PostedCashDocHeader.PrintRecords(true);
                end;
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }
}


#endif