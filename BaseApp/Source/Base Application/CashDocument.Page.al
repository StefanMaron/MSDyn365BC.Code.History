#if not CLEAN17
page 11730 "Cash Document"
{
    Caption = 'Cash Document (Obsolete)';
    DelayedInsert = true;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Request Approval';
    RefreshOnActivate = true;
    SourceTable = "Cash Document Header";
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
                field("Cash Document Type"; "Cash Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies if the cash desk document represents a cash receipt (Receipt) or a withdrawal (Wirthdrawal)';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;

                        UpdateEditable;
                        SetShowMandatoryConditions
                    end;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the cash document.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Payment Purpose"; "Payment Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a payment purpose.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DateEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the posting of the cash document will be recorded.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DateEditable;
                    ToolTip = 'Specifies the date on which you created the document.';
                }
                field("VAT Date"; "VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DateEditable;
                    ToolTip = 'Specifies the VAT date. This date must be shown on the VAT statement.';
                }
                field("Paid To"; "Paid To")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = WithdrawalEditable;
                    ShowMandatory = WithdrawalToChecking;
                    ToolTip = 'Specifies whom is paid.';
                }
                field("Received From"; "Received From")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = ReceiptEditable;
                    ShowMandatory = ReceiveToChecking;
                    ToolTip = 'Specifies who recieved amount.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if cash desk document status is Open or Released.';
                }
                field("Amounts Including VAT"; "Amounts Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        CalcFields("VAT Base Amount (LCY)", "Amount Including VAT (LCY)");
                    end;
                }
                field("Released Amount"; "Released Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the cash desk document, in the currency of the cash document after releasing.';
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
                field("EET Cash Register"; "EET Cash Register")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies that the cash register works with EET.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
                    ObsoleteTag = '18.0';
                }
            }
            part(CashDocLines; "Cash Document Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Cash Desk No." = FIELD("Cash Desk No."),
                              "Cash Document No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the partner is Customer or Vendor or Contact or Salesperson/Purchaser or Employee.';
                }
                field("Partner No."; "Partner No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the partner number.';
                }
                field("Paid By"; "Paid By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = WithdrawalEditable;
                    ShowMandatory = WithdrawalToChecking;
                    ToolTip = 'Specifies whom is paid.';
                }
                field("Received By"; "Received By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = ReceiptEditable;
                    ShowMandatory = ReceiveToChecking;
                    ToolTip = 'Specifies who recieved amount.';
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

                    trigger OnValidate()
                    begin
                        CurrPage.CashDocLines.PAGE.UpdatePage(true);
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the Shortcut Dimension 2, which is defined in the Shortcut Dimension 2 Code field in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        CurrPage.CashDocLines.PAGE.UpdatePage(true);
                    end;
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
                field("Created ID"; "Created ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies employee ID of creating cash desk document.';
                }
                field("Created Date"; "Created Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
            }
            part(Control1220064; "Approval FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = CONST(11708),
                              "Document No." = FIELD("No.");
                Visible = false;
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
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected cash document.';

                    trigger OnAction()
                    begin
                        CurrPage.CashDocLines.PAGE.ShowStatistics;
                    end;
                }
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
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Relations to the workflow.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Rejects credit document';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Specifies enu delegate of cash document.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Specifies cash document comments.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Cash Document Rounding")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Document Rounding';
                    Image = Calculate;
                    ToolTip = 'Specifies rounding of cash document.';

                    trigger OnAction()
                    begin
                        VATRounding;
                    end;
                }
                action("Link Advance Letters")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link Advance Letters (Obsolete)';
                    Enabled = LinkAdvLettersEnabled;
                    Image = LinkWithExisting;
                    ToolTip = 'Allow to link partial payment of advance letters.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;

                    trigger OnAction()
                    begin
                        CurrPage.CashDocLines.PAGE.LinkAdvLetters;
                    end;
                }
                action("Link Whole Advance Letter")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link Whole Advance Letter (Obsolete)';
                    Image = LinkAccount;
                    ToolTip = 'Allow to link whole advance letters.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;

                    trigger OnAction()
                    begin
                        CurrPage.CashDocLines.PAGE.LinkWholeAdvLetter;
                    end;
                }
                action("UnLink Linked Advance Letters")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'UnLink Linked Advance Letters (Obsolete)';
                    Image = UnLinkAccount;
                    ToolTip = 'Unlinks linked advance letters';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;

                    trigger OnAction()
                    begin
                        CurrPage.CashDocLines.PAGE.UnLinkLinkedAdvLetters;
                    end;
                }
                action(CopyDocument)
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a new cash document by copying an existing cash document.';

                    trigger OnAction()
                    var
                        CopyCashDoc: Report "Copy Cash Document";
                    begin
                        CopyCashDoc.SetCashDocument(Rec);
                        CopyCashDoc.RunModal;
                        Clear(CopyCashDoc);
                        if Get("Cash Desk No.", "No.") then;
                    end;
                }
            }
            group("&Releasing")
            {
                Caption = '&Releasing';
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the cash document to indicate that it has been account. The status then changes to Released.';

                    trigger OnAction()
                    begin
                        ReleaseDocument(CODEUNIT::"Cash Document-Release", NavigateAfterRelease::"Released Document");
                    end;
                }
                action(ReleaseAndNew)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release and New';
                    Image = ReleaseDoc;
                    ToolTip = 'Release the cash document to indicate that can be posted and create new cash document with same type. The status then changes to Released.';

                    trigger OnAction()
                    begin
                        ReleaseDocument(CODEUNIT::"Cash Document-Release", NavigateAfterRelease::"New Document");
                    end;
                }
                action(ReleaseAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release and &Print';
                    Image = ConfirmAndPrint;
                    ToolTip = 'Release and prepare to print the cash document.';

                    trigger OnAction()
                    begin
                        ReleaseDocument(CODEUNIT::"Cash Document-Release + Print", NavigateAfterRelease::"Do Nothing");
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        CashDocumentRelease: Codeunit "Cash Document-Release";
                    begin
                        CashDocumentRelease.PerformManualReopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostDocument;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the cash document. The values are posted to the related accounts.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Cash Document-Post (Yes/No)", NavigateAfterPost::"Posted Document");
                    end;
                }
                action(PostAndNew)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and New';
                    Ellipsis = true;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize the cash document and create new cash document with same type. The values are posted to the related accounts.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Cash Document-Post (Yes/No)", NavigateAfterPost::"New Document");
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ToolTip = 'Finalize and prepare to print the cash document. The values are posted to the related accounts.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Cash Document-Post + Print", NavigateAfterPost::"Do Nothing");
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
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
        SetShowMandatoryConditions;
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateEditable;
        UpdateEnabled;
        SetControlVisibility;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        TestField(Status, Status::Open);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        CashDeskMgt: Codeunit CashDeskManagement;
        CashDeskNo: Code[20];
        CashDeskSelected: Boolean;
    begin
        if CashDeskNo = '' then begin
            CashDeskNo := UniSingleInstCU.getCashDeskNo;
            if GetFilter("Cash Desk No.") <> '' then
                if GetRangeMin("Cash Desk No.") = GetRangeMax("Cash Desk No.") then
                    CashDeskNo := GetRangeMin("Cash Desk No.");
        end;

        if CashDeskNo = '' then begin
            CashDeskMgt.CashDocumentSelection(Rec, CashDeskSelected);
            if not CashDeskSelected then
                Error('');
        end else begin
            FilterGroup(2);
            SetRange("Cash Desk No.", CashDeskNo);
            FilterGroup(0);
        end;

        FilterGroup(2);
        "Cash Desk No." := CopyStr(GetFilter("Cash Desk No."), 1, MaxStrLen("Cash Desk No."));
        FilterGroup(0);
    end;

    var
        UniSingleInstCU: Codeunit "Universal Single Inst. CU";
        ChangeExchangeRate: Page "Change Exchange Rate";
        NavigateAfterPost: Option "Posted Document","New Document","Do Nothing";
        NavigateAfterRelease: Option "Released Document","New Document","Do Nothing";
        [InDataSet]
        DateEditable: Boolean;
        ReceiptEditable: Boolean;
        WithdrawalEditable: Boolean;
        ReceiveToChecking: Boolean;
        WithdrawalToChecking: Boolean;
        ShowWorkflowStatus: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        [InDataSet]
        LinkAdvLettersEnabled: Boolean;
        OpenPostedCashDocQst: Label 'The cash document has been posted and moved to the Posted Cash Documents window.\\Do you want to open the posted cash document?';
        DocumentIsPosted: Boolean;
        DocumentIsReleased: Boolean;

    local procedure PostDocument(PostingCodeunitID: Integer; Navigate: Option)
    var
        CashDocumentHeader: Record "Cash Document Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        SendToPosting(PostingCodeunitID);
        DocumentIsPosted := not CashDocumentHeader.Get("Cash Desk No.", "No.");

        CurrPage.Update(false);

        if PostingCodeunitID <> CODEUNIT::"Cash Document-Post (Yes/No)" then
            exit;

        case Navigate of
            NavigateAfterPost::"Posted Document":
                if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
                    ShowPostedConfirmationMessage("Cash Desk No.", "No.");
            NavigateAfterPost::"New Document":
                if DocumentIsPosted then
                    ShowNewCashDocument;
        end;
    end;

    local procedure ReleaseDocument(ReleasingCodeunitID: Integer; Navigate: Option)
    var
        CashDocumentHeader: Record "Cash Document Header";
        CashDocRelease: Codeunit "Cash Document-Release";
        CashDocReleasePrint: Codeunit "Cash Document-Release + Print";
    begin
        case ReleasingCodeunitID of
            CODEUNIT::"Cash Document-Release":
                CashDocRelease.PerformManualRelease(Rec);
            CODEUNIT::"Cash Document-Release + Print":
                CashDocReleasePrint.PerformManualRelease(Rec);
        end;

        CashDocumentHeader.Get("Cash Desk No.", "No.");
        DocumentIsReleased := CashDocumentHeader.Status = CashDocumentHeader.Status::Released;

        CurrPage.Update(false);

        if ReleasingCodeunitID <> CODEUNIT::"Cash Document-Release" then
            exit;

        case Navigate of
            NavigateAfterRelease::"New Document":
                if DocumentIsReleased then
                    ShowNewCashDocument;
        end;
    end;

    local procedure UpdateEditable()
    begin
        DateEditable := Status = Status::Open;
        ReceiptEditable := "Cash Document Type" = "Cash Document Type"::Receipt;
        WithdrawalEditable := "Cash Document Type" = "Cash Document Type"::Withdrawal;
    end;

    local procedure UpdateEnabled()
    begin
        LinkAdvLettersEnabled := not IsEETCashRegister;
    end;

    local procedure SetShowMandatoryConditions()
    var
        BankAccount: Record "Bank Account";
    begin
        if not BankAccount.Get("Cash Desk No.") then
            BankAccount.Init();

        ReceiveToChecking :=
          ("Cash Document Type" = "Cash Document Type"::Receipt) and
          (BankAccount."Payed To/By Checking" <> BankAccount."Payed To/By Checking"::"No Checking");
        WithdrawalToChecking :=
          ("Cash Document Type" = "Cash Document Type"::Withdrawal) and
          (BankAccount."Payed To/By Checking" <> BankAccount."Payed To/By Checking"::"No Checking");
    end;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;

    local procedure ShowPreview()
    var
        CashDocumentPostYesNo: Codeunit "Cash Document-Post (Yes/No)";
    begin
        CashDocumentPostYesNo.Preview(Rec);
    end;

    local procedure ShowPostedConfirmationMessage(CashDeskNo: Code[20]; CashDocumentNo: Code[20])
    var
        PostedCashDocumentHeader: Record "Posted Cash Document Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        PostedCashDocumentHeader.SetRange("Cash Desk No.", CashDeskNo);
        PostedCashDocumentHeader.SetRange("No.", CashDocumentNo);
        if PostedCashDocumentHeader.FindFirst then
            if InstructionMgt.ShowConfirm(OpenPostedCashDocQst, InstructionMgt.ShowPostedConfirmationMessageCode) then
                PAGE.Run(PAGE::"Posted Cash Document", PostedCashDocumentHeader);
    end;

    local procedure ShowNewCashDocument()
    var
        CashDocumentHeader: Record "Cash Document Header";
    begin
        CashDocumentHeader.Init();
        CashDocumentHeader.Validate("Cash Desk No.", "Cash Desk No.");
        CashDocumentHeader.Validate("Cash Document Type", "Cash Document Type");
        CashDocumentHeader.Insert(true);
        PAGE.Run(PAGE::"Cash Document", CashDocumentHeader);
    end;
}
#endif