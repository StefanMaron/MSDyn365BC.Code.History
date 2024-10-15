page 11732 "Cash Document List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Documents';
    CardPageID = "Cash Document";
    DataCaptionFields = "Cash Desk No.";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Approve,Request Approval';
    SourceTable = "Cash Document Header";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1220015)
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
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if cash desk document status is Open or Released.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the posting of the cash document will be recorded.';
                }
                field("Released Amount"; "Released Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the cash desk document, in the currency of the cash document after releasing.';
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
            group("Cash Document")
            {
                Caption = 'Cash Document';
                Image = Document;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit the dimension sets that are set up for the cash document.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
                action("A&pprovals")
                {
                    ApplicationArea = Suite;
                    Caption = 'A&pprovals';
                    Image = Approvals;
                    ToolTip = 'This function opens the approvals entries.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(RecordId);
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Releasing")
            {
                Caption = '&Releasing';
                action("&Release")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the cash document to indicate that it has been account. The status then changes to Released.';

                    trigger OnAction()
                    var
                        CashDocHeader: Record "Cash Document Header";
                        CashDocRelease: Codeunit "Cash Document-Release";
                    begin
                        CashDocHeader := Rec;
                        CashDocHeader.SetRecFilter;
                        CashDocRelease.PerformManualRelease(CashDocHeader);
                        CurrPage.Update(false);
                    end;
                }
                action("Release and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release and &Print';
                    Image = ConfirmAndPrint;
                    ToolTip = 'Release and prepare to print the cash document.';

                    trigger OnAction()
                    var
                        CashDocHeader: Record "Cash Document Header";
                        CashDocReleasePrint: Codeunit "Cash Document-Release + Print";
                    begin
                        CashDocHeader := Rec;
                        CashDocHeader.SetRecFilter;
                        CashDocReleasePrint.PerformManualRelease(CashDocHeader);
                        CurrPage.Update(false);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostDocument;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the cash document. The values are posted to the related accounts.';

                    trigger OnAction()
                    begin
                        Post(CODEUNIT::"Cash Document-Post (Yes/No)");
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the cash document. The values are posted to the related accounts.';

                    trigger OnAction()
                    begin
                        Post(CODEUNIT::"Cash Document-Post + Print");
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ToolTip = 'Review the result of the posting lines before the actual posting.';

                    trigger OnAction()
                    begin
                        ShowPreview;
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckCashDocApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendCashDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelCashDocApprovalRequest(Rec);
                    end;
                }
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
                    CashDocHeader: Record "Cash Document Header";
                begin
                    CashDocHeader := Rec;
                    CashDocHeader.SetRecFilter;
                    CashDocHeader.PrintRecords(true);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance;
        UniSingleInstCU.setCashDeskNo("Cash Desk No.");
    end;

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
        UniSingleInstCU: Codeunit "Universal Single Inst. CU";
        CashDeskMgt: Codeunit CashDeskManagement;
        OpenApprovalEntriesExist: Boolean;

    local procedure Post(PostingCodeunitID: Integer)
    var
        CashDocHeader: Record "Cash Document Header";
    begin
        CashDocHeader := Rec;
        CashDocHeader.SetRecFilter;
        CashDocHeader.SendToPosting(PostingCodeunitID);
        CurrPage.Update(false);
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;

    local procedure ShowPreview()
    var
        CashDocumentPostYesNo: Codeunit "Cash Document-Post (Yes/No)";
    begin
        CashDocumentPostYesNo.Preview(Rec);
    end;
}

