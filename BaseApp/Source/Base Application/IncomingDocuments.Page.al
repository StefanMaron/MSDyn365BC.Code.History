page 190 "Incoming Documents"
{
    AdditionalSearchTerms = 'electronic document,e-invoice,ocr,ecommerce,document exchange,import invoice';
    ApplicationArea = Basic, Suite;
    Caption = 'Incoming Documents';
    CardPageID = "Incoming Document";
    DataCaptionFields = Description;
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Release,Status,Show';
    RefreshOnActivate = true;
    SourceTable = "Incoming Document";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the incoming document. You must enter the description manually.';
                }
                field("Vendor Name"; "Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor on the incoming document. The field may be filled automatically.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that is printed on the incoming document. This is the date when the vendor created the invoice, for example. The field may be filled automatically.';
                }
                field("Vendor Invoice No."; "Vendor Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code, if the document contains that code. The field may be filled automatically.';
                }
                field("Amount Incl. VAT"; "Amount Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount including VAT for the whole document. The field may be filled automatically.';
                }
                field(URL; URL)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link to Document';
                    ExtendedDatatype = URL;
                    Importance = Additional;
                    ToolTip = 'Specifies the location of the file that represents the incoming document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SetURL(URL);
                    end;
                }
                field("Data Exchange Type"; "Data Exchange Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsDataExchTypeEditable;
                    ToolTip = 'Specifies the data exchange type that is used to process the incoming document when it is an electronic document.';
                    Visible = false;
                }
                field(StatusField; Status)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    StyleExpr = StatusStyleText;
                    ToolTip = 'Specifies the status of the incoming document record.';

                    trigger OnDrillDown()
                    var
                        ErrorMessage: Record "Error Message";
                    begin
                        ErrorMessage.SetContext(RecordId);
                        ErrorMessage.ShowErrorMessages(false);
                    end;
                }
                field("OCR Status"; "OCR Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the incoming document record when it takes part in the OCR process.';

                    trigger OnDrillDown()
                    var
                        OCRServiceSetup: Record "OCR Service Setup";
                        OCRServiceMgt: Codeunit "OCR Service Mgt.";
                    begin
                        if not OCRServiceSetup.IsEmpty then
                            HyperLink(OCRServiceMgt.GetStatusHyperLink(Rec));
                    end;
                }
                field("OCR Track ID"; "OCR Track ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the process stage of the track ID in relation to the OCR service.';
                }
                field("Created Date-Time"; "Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the incoming document line was created.';
                    Visible = false;
                }
                field("Created By User Name"; "Created By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user who created the incoming document line.';
                    Visible = false;
                }
                field("Released Date-Time"; "Released Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the incoming document was approved.';
                    Visible = false;
                }
                field("Released By User Name"; "Released By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user who approved the incoming document.';
                    Visible = false;
                }
                field("Last Date-Time Modified"; "Last Date-Time Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the incoming document line was last modified.';
                    Visible = false;
                }
                field("Last Modified By User Name"; "Last Modified By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the user who last modified the incoming document line.';
                    Visible = false;
                }
                field("Posted Date-Time"; "Posted Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the related document or journal line was posted.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document or journal that the incoming document can be connected to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document or journal line that is created for the incoming document.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the document or journal line that relates to the incoming document was posted.';
                    Visible = false;
                }
                field(Processed; Processed)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    StyleExpr = StatusStyleText;
                    ToolTip = 'Specifies if the incoming document has been processed.';

                    trigger OnDrillDown()
                    var
                        ErrorMessage: Record "Error Message";
                    begin
                        ErrorMessage.SetContext(RecordId);
                        ErrorMessage.ShowErrorMessages(false);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                SubPageLink = "Incoming Document Entry No." = FIELD("Entry No.");
            }
            systempart(Control19; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control20; MyNotes)
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            systempart(Control21; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(CreateFromCamera)
            {
                ApplicationArea = All;
                Caption = 'Create from Camera';
                Image = Camera;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                ToolTip = 'Create a new incoming document record by taking a picture.';
                Visible = HasCamera;

                trigger OnAction()
                var
                    InStr: InStream;
                begin
                    if not HasCamera then
                        exit;
                    Camera.SetQuality(100); // 100%
                    Camera.RunModal();
                    if Camera.HasPicture() then begin
                        Camera.GetPicture(InStr);
                        CreateIncomingDocument(InStr, 'Incoming Document');
                    end;
                    Clear(Camera);
                end;
            }
            action(CreateFromAttachment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create from File';
                Image = ExportAttachment;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                ToolTip = 'Create a new incoming document record by first selecting the file it will be based on. The selected file will be attached.';

                trigger OnAction()
                begin
                    CreateFromAttachment;
                end;
            }
        }
        area(navigation)
        {
            group(Action28)
            {
                Caption = 'Setup';
                action(Setup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setup';
                    Image = Setup;
                    RunObject = Page "Incoming Documents Setup";
                    ToolTip = 'Define the general journal type to use when creating journal lines. You can also specify whether it requires approval to create documents and journal lines.';
                }
                action(DataExchangeTypes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data Exchange Types';
                    Image = Entries;
                    RunObject = Page "Data Exchange Types";
                    ToolTip = 'View the data exchange types that are available to convert electronic documents to documents in Dynamics 365.';
                }
                action(OCRSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OCR Service Setup';
                    Image = ServiceSetup;
                    ToolTip = 'Open the OCR Service Setup window, for example to change credentials or enable the service.';
                    Visible = ShowOCRSetup;

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"OCR Service Setup");
                        CurrPage.Update;
                        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Web then
                            if OCRIsEnabled then begin
                                OnCloseIncomingDocumentsFromActions(Rec);
                                CurrPage.Close;
                            end;
                    end;
                }
            }
            action(ApprovalEntries)
            {
                AccessByPermission = TableData "Approval Entry" = R;
                ApplicationArea = Suite;
                Caption = 'Approvals';
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
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(CreateDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Document';
                    Enabled = AutomaticCreationActionsAreEnabled;
                    Image = CreateDocument;
                    ToolTip = 'Create a document, such as a purchase invoice, automatically by converting the electronic document that is attached to the incoming document record.';

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::CreateDocument);
                        CurrPage.Update;
                    end;
                }
                action(CreateGenJnlLine)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Journal Line';
                    Enabled = AutomaticCreationActionsAreEnabled;
                    Image = TransferToGeneralJournal;
                    ToolTip = 'Create a journal line automatically by converting the electronic document that is attached to the incoming document record.';

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::CreateGenJnlLineWithDataExchange);
                        CurrPage.Update;
                    end;
                }
                action(CreateManually)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Manually';
                    Image = CreateCreditMemo;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create a document, such as a purchase invoice, manually from information in the file that is attached to the incoming document record.';

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::CreateManually);
                    end;
                }
                action(AttachFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attach File';
                    Image = Attach;
                    Scope = Repeater;
                    ToolTip = 'Attach a file to the incoming document record.';

                    trigger OnAction()
                    begin
                        ImportAttachment(Rec);
                    end;
                }
                action(TextToAccountMapping)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Map Text to Account';
                    Image = MapAccounts;
                    RunObject = Page "Text-to-Account Mapping Wksh.";
                    ToolTip = 'Create a mapping of text on incoming documents to identical text on specific debit, credit, and balancing accounts in the general ledger or on bank accounts so that the resulting document or journal lines are prefilled with the specified information.';
                }
            }
            group(Action53)
            {
                Caption = 'Release';
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Release the incoming document to indicate that it has been approved by the incoming document approver.';

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::Release);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Reopen the incoming document record after it has been approved by the incoming document approver.';

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::Reopen);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Reject to approve the incoming document.';

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::Reject);
                    end;
                }
            }
            group(Status)
            {
                Caption = 'Status';
                action(SetToProcessed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set To Processed';
                    Enabled = SetToProcessedIsEnable;
                    Image = Archive;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Set the incoming document to processed. It will then be shown in the Incoming Documents window when the Show All view is selected.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        CurrPage.SetSelectionFilter(IncomingDocument);
                        IncomingDocument.ModifyAll(Processed, true);
                    end;
                }
                action(SetToUnprocessed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set To Unprocessed';
                    Enabled = NOT SetToProcessedIsEnable;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Set the incoming document to unprocessed. It will then be shown in the Incoming Documents window when the Show Unprocessed view is selected.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        CurrPage.SetSelectionFilter(IncomingDocument);
                        IncomingDocument.ModifyAll(Processed, false);
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
                    Scope = Repeater;
                    ToolTip = 'Request approval of the incoming document. You can send an approval request as part of a workflow if this has been set up in your organization.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        TestReadyForApproval;
                        if ApprovalsMgmt.CheckIncomingDocApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendIncomingDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord;
                    Image = CancelApprovalRequest;
                    Scope = Repeater;
                    ToolTip = 'Cancel requesting approval of the incoming document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelIncomingDocApprovalRequest(Rec);
                    end;
                }
            }
            group("Incoming Documents")
            {
                Caption = 'Incoming Documents';
                action(OpenDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Record';
                    Image = ViewDetails;
                    Scope = Repeater;
                    ToolTip = 'Open the document, journal line, or entry that the incoming document is linked to.';

                    trigger OnAction()
                    begin
                        ShowRecord;
                    end;
                }
                action(RemoveReferencedRecord)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Reference to Record';
                    Image = ClearLog;
                    Scope = Repeater;
                    ToolTip = 'Remove the link that exists from the incoming document to a document, journal line, or entry.';

                    trigger OnAction()
                    begin
                        RemoveReferencedRecords;
                    end;
                }
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Navigate';
                    Image = Navigate;
                    Scope = Repeater;
                    ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                    trigger OnAction()
                    var
                        NavigatePage: Page Navigate;
                    begin
                        TestField(Posted);
                        NavigatePage.SetDoc("Posting Date", "Document No.");
                        NavigatePage.Run;
                    end;
                }
                group(Document)
                {
                    Caption = 'Record';
                    Enabled = false;
                    Image = Document;
                    Visible = false;
                    action(Journal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Line';
                        Image = Journal;
                        Scope = Repeater;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        var
                            GenJournalBatch: Record "Gen. Journal Batch";
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            IncomingDocumentMultiSelectAction(MultiSelectAction::CreateGenJnlLine);
                            IncomingDocumentsSetup.Fetch;
                            GenJournalBatch.Get(IncomingDocumentsSetup."General Journal Template Name", IncomingDocumentsSetup."General Journal Batch Name");
                            GenJnlManagement.TemplateSelectionFromBatch(GenJournalBatch);
                        end;
                    }
                    action(PurchaseInvoice)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Invoice';
                        Image = Purchase;
                        Scope = Repeater;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            IncomingDocumentMultiSelectAction(MultiSelectAction::CreatePurchInvoice);
                        end;
                    }
                    action(PurchaseCreditMemo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Credit Memo';
                        Image = CreditMemo;
                        Scope = Repeater;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            IncomingDocumentMultiSelectAction(MultiSelectAction::CreatePurchCreditMemo);
                        end;
                    }
                    action(SalesInvoice)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Invoice';
                        Image = Sales;
                        Scope = Repeater;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            IncomingDocumentMultiSelectAction(MultiSelectAction::CreateSalesInvoice);
                        end;
                    }
                    action(SalesCreditMemo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Credit Memo';
                        Image = CreditMemo;
                        Scope = Repeater;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            IncomingDocumentMultiSelectAction(MultiSelectAction::CreateSalesCreditMemo);
                        end;
                    }
                }
            }
            group(OCR)
            {
                Caption = 'OCR';
                action(SetReadyForOCR)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send to Job Queue';
                    Image = Translation;
                    ToolTip = 'Set the incoming document to be sent to its recipient as soon as possible.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::SetReadyForOcr);
                    end;
                }
                action(UndoSetReadyForOCR)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove from Job Queue';
                    Image = Translation;
                    ToolTip = 'Remove the scheduled processing of this record from the job queue.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::UndoReadyForOcr);
                    end;
                }
                action(SendToOcr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send to OCR Service';
                    Image = Translations;
                    ToolTip = 'Send the attached PDF or image file to the OCR service immediately.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        IncomingDocumentMultiSelectAction(MultiSelectAction::SendToOcr);
                    end;
                }
                action(ReceiveFromOCR)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receive from OCR Service';
                    Enabled = EnableReceiveFromOCR;
                    Image = Import;
                    ToolTip = 'Get any electronic documents that are ready to receive from the OCR service.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"OCR - Receive from Service");
                    end;
                }
            }
            group("Set View")
            {
                Caption = 'Set View';
                action(ShowAll)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All';
                    Enabled = NOT ShowAllDocsIsEnable;
                    Image = AllLines;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ToolTip = 'Show both processed and non-processed incoming documents.';

                    trigger OnAction()
                    begin
                        SetProcessedDocumentsVisibility(true);
                    end;
                }
                action(ShowUnprocessed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Unprocessed';
                    Enabled = ShowAllDocsIsEnable;
                    Image = Document;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ToolTip = 'Show only unprocessed incoming documents.';

                    trigger OnAction()
                    begin
                        SetProcessedDocumentsVisibility(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsDataExchTypeEditable := not (Status in [Status::Created, Status::Posted]);
        StatusStyleText := GetStatusStyleText;
        SetControlVisibility;
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromIncomingDocument(Rec);
        SetToProcessedIsEnable := not Processed;
    end;

    trigger OnAfterGetRecord()
    begin
        URL := GetURL;
        StatusStyleText := GetStatusStyleText;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        URL := '';
        StatusStyleText := GetStatusStyleText;
    end;

    trigger OnOpenPage()
    begin
        IsDataExchTypeEditable := true;
        if GuiAllowed then begin
            HasCamera := Camera.IsAvailable()
        end;
        EnableReceiveFromOCR := WaitingToReceiveFromOCR;
        UpdateOCRSetupVisibility;

        FilterGroup(0);
        SetProcessedDocumentsVisibility(GetFilter(Processed) = Format(true));
    end;

    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        AutomaticProcessingQst: Label 'The Data Exchange Type field is filled on at least one of the selected Incoming Documents.\\Are you sure you want to create documents manually?';
        ClientTypeManagement: Codeunit "Client Type Management";
        Camera: Page Camera;
        [InDataSet]
        HasCamera: Boolean;
        URL: Text;
        StatusStyleText: Text;
        MultiSelectAction: Option CreateGenJnlLine,CreatePurchInvoice,CreatePurchCreditMemo,CreateSalesInvoice,CreateSalesCreditMemo,Release,Reopen,Reject,CreateDocument,SetReadyForOcr,UndoReadyForOcr,SendToOcr,CreateGenJnlLineWithDataExchange,CreateManually;
        IsDataExchTypeEditable: Boolean;
        OpenApprovalEntriesExist: Boolean;
        EnableReceiveFromOCR: Boolean;
        CanCancelApprovalForRecord: Boolean;
        ShowOCRSetup: Boolean;
        OCRServiceIsEnabled: Boolean;
        AutomaticCreationActionsAreEnabled: Boolean;
        SetToProcessedIsEnable: Boolean;
        ShowAllDocsIsEnable: Boolean;

    local procedure IncomingDocumentMultiSelectAction(ActionName: Option)
    var
        IncomingDocument: Record "Incoming Document";
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
    begin
        if not AskUserPermission(ActionName) then
            exit;

        CurrPage.SetSelectionFilter(IncomingDocument);
        if IncomingDocument.FindSet then
            repeat
                case ActionName of
                    MultiSelectAction::CreateDocument:
                        IncomingDocument.CreateDocumentWithDataExchange;
                    MultiSelectAction::CreateManually:
                        IncomingDocument.CreateManually;
                    MultiSelectAction::CreateGenJnlLine:
                        IncomingDocument.CreateGenJnlLine;
                    MultiSelectAction::CreateGenJnlLineWithDataExchange:
                        IncomingDocument.CreateGeneralJournalLineWithDataExchange;
                    MultiSelectAction::CreatePurchInvoice:
                        IncomingDocument.CreatePurchInvoice;
                    MultiSelectAction::CreatePurchCreditMemo:
                        IncomingDocument.CreatePurchCreditMemo;
                    MultiSelectAction::CreateSalesInvoice:
                        IncomingDocument.CreateSalesInvoice;
                    MultiSelectAction::CreateSalesCreditMemo:
                        IncomingDocument.CreateSalesCreditMemo;
                    MultiSelectAction::Release:
                        ReleaseIncomingDocument.PerformManualRelease(IncomingDocument);
                    MultiSelectAction::Reopen:
                        ReleaseIncomingDocument.PerformManualReopen(IncomingDocument);
                    MultiSelectAction::Reject:
                        ReleaseIncomingDocument.PerformManualReject(IncomingDocument);
                    MultiSelectAction::SetReadyForOcr:
                        IncomingDocument.SendToJobQueue(false);
                    MultiSelectAction::UndoReadyForOcr:
                        IncomingDocument.RemoveFromJobQueue(false);
                    MultiSelectAction::SendToOcr:
                        IncomingDocument.SendToOCR(false);
                end;
            until IncomingDocument.Next = 0;
    end;

    local procedure AskUserPermission(ActionName: Option): Boolean
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CurrPage.SetSelectionFilter(IncomingDocument);
        if ActionName in [MultiSelectAction::Reject,
                          MultiSelectAction::Release,
                          MultiSelectAction::SetReadyForOcr,
                          MultiSelectAction::CreateDocument]
        then
            exit(true);

        if Status <> Status::New then
            exit(true);

        IncomingDocument.SetFilter("Data Exchange Type", '<>%1', '');
        if IncomingDocument.IsEmpty then
            exit(true);

        exit(Confirm(AutomaticProcessingQst));
    end;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        EnableReceiveFromOCR := WaitingToReceiveFromOCR;
        UpdateOCRSetupVisibility;
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
        AutomaticCreationActionsAreEnabled := "Data Exchange Type" <> '';
    end;

    [IntegrationEvent(TRUE, TRUE)]
    local procedure OnCloseIncomingDocumentsFromActions(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    local procedure SetProcessedDocumentsVisibility(ShowProcessedItems: Boolean)
    begin
        FilterGroup(0);

        if ShowProcessedItems then begin
            SetRange(Processed);
            ShowAllDocsIsEnable := true;
        end else begin
            SetRange(Processed, false);
            ShowAllDocsIsEnable := false;
        end;
    end;

    local procedure UpdateOCRSetupVisibility()
    begin
        OCRServiceIsEnabled := OCRIsEnabled;
        ShowOCRSetup := not OCRServiceIsEnabled;
    end;
}

