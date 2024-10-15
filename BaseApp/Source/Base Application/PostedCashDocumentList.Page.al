#if not CLEAN17
page 11737 "Posted Cash Document List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Cash Documents (Obsolete)';
    CardPageID = "Posted Cash Document";
    DataCaptionFields = "Cash Desk No.";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Cash Document Header";
    UsageCategory = History;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220013)
            {
                ShowCaption = false;
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
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the cash document was posted.';
                }
                field("VAT Base Amount"; "VAT Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total VAT base amount for lines. The program calculates this amount from the sum of line VAT base amount fields.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Payment Purpose"; "Payment Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payment purpose.';
                }
                field("Received From"; "Received From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who recieved amount.';
                    Visible = false;
                }
                field("Paid To"; "Paid To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whom is paid.';
                    Visible = false;
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

    trigger OnOpenPage()
    var
        CashDeskFilter: Text;
    begin
        CashDeskMgt.CheckCashDesks;
        CashDeskFilter := CashDeskMgt.GetCashDesksFilter;

        FilterGroup(2);
        if CashDeskFilter <> '' then
            SetFilter("Cash Desk No.", CashDeskFilter);
        FilterGroup(0);
    end;

    var
        CashDeskMgt: Codeunit CashDeskManagement;
}


#endif