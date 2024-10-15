page 31022 "Purchase Advance Letters"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Purchase Advance Letters';
    CardPageID = "Purchase Advance Letter";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Approve,Request Approval';
    SourceTable = "Purch. Advance Letter Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1220012)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the purchase advance letter.';
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor who is sending the invoice.';
                }
                field("Pay-to Name"; "Pay-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor sending the invoice.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the stage during advance process.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("Amount on Payment Order (LCY)"; "Amount on Payment Order (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount on payment order.';
                    Visible = false;
                }
                field("Template Code"; "Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an advance template code.';
                    Visible = false;
                }
                field("Amount To Link"; "Amount To Link")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount not yet paid by customer.';
                    Visible = false;
                }
                field("Amount To Invoice"; "Amount To Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the paid amount for advance VAT document.';
                    Visible = false;
                }
                field("Amount To Deduct"; "Amount To Deduct")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum advance value for use in final sales invoice.';
                    Visible = false;
                }
                field("Document Linked Amount"; "Document Linked Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document linked amount.';
                    Visible = false;
                }
                field("Vendor Adv. Payment No."; "Vendor Adv. Payment No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1100171003; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1100171001; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Letter")
            {
                Caption = '&Letter';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected advance letter.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Purch. Adv. Letter Statistics", Rec);
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'Specifies advance dimensions.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "No." = FIELD("No."),
                                  "Document Line No." = CONST(0),
                                  "Document Type" = CONST("Advance Letter");
                    ToolTip = 'Specifies advance comments.';
                }
                action("A&pprovals")
                {
                    ApplicationArea = Suite;
                    Caption = 'A&pprovals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(RecordId);
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                action("Assignment Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assignment Documents';
                    Image = Documents;
                    ToolTip = 'Conection to the purchase document.';

                    trigger OnAction()
                    begin
                        ShowDocs;
                    end;
                }
                action("Assignment Documents - detail")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assignment Documents - detail';
                    Image = ViewDetails;
                    RunObject = Page "Advance Letter Line Relations";
                    RunPageLink = Type = CONST(Purchase),
                                  "Letter No." = FIELD("No.");
                    RunPageView = SORTING(Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.");
                    ToolTip = 'Conection to the purchase document.';
                }
                action("Li&nked Advance Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Li&nked Advance Payments';
                    Image = Payment;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Show the advance payments by vendor';

                    trigger OnAction()
                    begin
                        ShowLinkedAdvances;
                    end;
                }
                action("Advance Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advance Invoices';
                    Image = Invoice;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Posted Purchase Invoices";
                    RunPageLink = "Letter No." = FIELD("No.");
                    RunPageView = SORTING("Letter No.");
                    ToolTip = 'Show advance invoice if they were posted.';
                }
                action("Advance Credi&t Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advance Credi&t Memos';
                    Image = CreditMemo;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Posted Purchase Credit Memos";
                    RunPageLink = "Letter No." = FIELD("No.");
                    RunPageView = SORTING("Letter No.");
                    ToolTip = 'Show advance credit memos if they were posted.';
                }
            }
        }
        area(processing)
        {
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Action1220026)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the purchase advance to indicate that it has been printed or exported. The status then changes to Released.';

                    trigger OnAction()
                    begin
                        PerformManualRelease;
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have tha Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    begin
                        PerformManualReopen;
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Advance Letter")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advance Letter';
                    Ellipsis = true;
                    Image = PrintReport;
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedIsBig = true;
                    ToolTip = 'Allows the print of advance letter.';

                    trigger OnAction()
                    begin
                        PurchAdvanceLetterHeader := Rec;
                        CurrPage.SetSelectionFilter(PurchAdvanceLetterHeader);
                        PurchAdvanceLetterHeader.PrintRecords(true);
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
                        if ApprovalsMgmt.CheckPurchaseAdvanceLetterApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendPurchaseAdvanceLetterForApproval(Rec);
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
                        ApprovalsMgmt.OnCancelPurchaseAdvanceLetterApprovalRequest(Rec);
                    end;
                }
            }
        }
        area(reporting)
        {
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        SetControlAppearance;
    end;

    trigger OnOpenPage()
    begin
        TemplateSelection;
        SetSecurityFilterOnRespCenter;
    end;

    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        OpenApprovalEntriesExist: Boolean;

    [Scope('OnPrem')]
    procedure TemplateSelection() Result: Boolean
    var
        PurchAdvPmtTemplate: Record "Purchase Adv. Payment Template";
    begin
        PurchAdvPmtTemplate.Reset;
        case PurchAdvPmtTemplate.Count of
            0:
                exit(Result);
            1:
                Result := PurchAdvPmtTemplate.FindFirst;
            else begin
                    Result := PAGE.RunModal(PAGE::"Purchase Adv. Paym. Selection", PurchAdvPmtTemplate) = ACTION::LookupOK;
                    if not Result then
                        Error('');
                end;
        end;

        if Result then begin
            SetCurrentKey("Template Code");
            FilterGroup := 2;
            SetRange("Template Code", PurchAdvPmtTemplate.Code);
            FilterGroup := 0;
        end;
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;
}

