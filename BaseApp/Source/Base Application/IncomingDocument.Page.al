page 189 "Incoming Document"
{
    Caption = 'Incoming Document';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Release,Status,Incoming Document,OCR,Approve,Request Approval';
    SourceTable = "Incoming Document";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the description of the incoming document. You must enter the description manually.';
                }
                field(URL; URL)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link to Document';
                    ExtendedDatatype = URL;
                    Importance = Additional;
                    ToolTip = 'Specifies a link to the attached file.';

                    trigger OnValidate()
                    begin
                        SetURL(URL);
                        CurrPage.Update;
                    end;
                }
                field(MainAttachment; AttachmentFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Main Attachment';
                    Editable = false;
                    Enabled = RecordHasAttachment;
                    ToolTip = 'Specifies the main attachment. Only this attachment is processed by the OCR and document exchange services.';

                    trigger OnDrillDown()
                    begin
                        MainAttachmentDrillDown;
                        CurrPage.Update;
                    end;
                }
                field("Data Exchange Type"; "Data Exchange Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsDataExchTypeEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the data exchange type that is used to process the incoming document when it is an electronic document.';

                    trigger OnValidate()
                    begin
                        if not DefaultAttachmentIsXML then
                            Error(InvalidTypeErr);
                    end;
                }
                field("Record"; RecordLinkTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record';
                    Editable = false;
                    ToolTip = 'Specifies the record, document, journal line, or ledger entry, that is linked to the incoming document.';

                    trigger OnDrillDown()
                    begin
                        ShowRecord;
                        CurrPage.Update;
                    end;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of document or journal that the incoming document can be connected to.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the related document or journal line that is created for the incoming document.';
                    Visible = false;
                }
                field(StatusField; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the incoming document record.';
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
                field("Job Queue Status"; "Job Queue Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the job queue entry that is processing the incoming document.';
                }
                group(Control71)
                {
                    ShowCaption = false;
                    field("OCR Service Doc. Template Code"; "OCR Service Doc. Template Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the code of the document template that you want the OCR service provider to use when they convert the incoming-document file to an electronic document. Chose the field to pick a supported document template from the OCR Service Setup window.';
                    }
                    field("OCR Service Doc. Template Name"; "OCR Service Doc. Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the document template that you want the OCR service provider to use when they convert the incoming-document file to an electronic document. Chose the field to pick a supported document template from the OCR Service Setup window.';
                    }
                    field(OCRResultFileName; OCRResultFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'OCR Result';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies what process stage the attached PDF or image file is in relation to the OCR service.';

                        trigger OnDrillDown()
                        begin
                            OCRResultDrillDown;
                            CurrPage.Update;
                        end;
                    }
                }
                group(Control72)
                {
                    ShowCaption = false;
                    field("Created Date-Time"; "Created Date-Time")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the incoming document line was created.';
                    }
                    field("Created By User Name"; "Created By User Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the user who created the incoming document line.';
                    }
                    field(Released; Released)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the incoming document has been approved.';
                        Visible = false;
                    }
                    field("Released Date-Time"; "Released Date-Time")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the incoming document was approved.';
                    }
                    field("Released By User Name"; "Released By User Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the user who approved the incoming document.';
                    }
                    field("Last Date-Time Modified"; "Last Date-Time Modified")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the incoming document line was last modified.';
                    }
                    field("Last Modified By User Name"; "Last Modified By User Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the user who last modified the incoming document line.';
                    }
                    field(Posted; Posted)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the document or journal line that was created for this incoming document has been posted.';
                    }
                    field("Posted Date-Time"; "Posted Date-Time")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the related document or journal line was posted.';
                    }
                    field("Posting Date"; "Posting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies when the document or journal line that relates to the incoming document was posted.';
                        Visible = false;
                    }
                }
            }
            part(SupportingAttachments; "Incoming Document Attachments")
            {
                ApplicationArea = All;
                Caption = 'Supporting Attachments';
                ShowFilter = false;
                Visible = AdditionalAttachmentsPresent;
            }
            group(FinancialInformation)
            {
                Caption = 'Financial Information';
                field("Vendor Name"; "Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the vendor on the incoming document. The field may be filled automatically.';
                }
                field("Vendor VAT Registration No."; "Vendor VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT registration number of the vendor, if the document contains that number. The field may be filled automatically.';
                }
                field("Vendor IBAN"; "Vendor IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the IBAN of the vendor on the incoming document.';
                }
                field("Vendor Bank Branch No."; "Vendor Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank branch number of the vendor on the incoming document.';
                }
                field("Vendor Bank Account No."; "Vendor Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account number of the vendor on the incoming document.';
                }
                field("Vendor Phone No."; "Vendor Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the phone number of the vendor on the incoming document.';
                }
                field("Vendor Invoice No."; "Vendor Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Order No.';
                    Editable = false;
                    ToolTip = 'Specifies the order number, if the document contains that number. The field may be filled automatically.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that is printed on the incoming document. This is the date when the vendor created the invoice, for example. The field may be filled automatically.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the vendor document must be paid. The field may be filled automatically.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code, if the document contains that code. The field may be filled automatically.';
                }
                field("Amount Excl. VAT"; "Amount Excl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount excluding VAT for the whole document. The field may be filled automatically.';
                }
                field("Amount Incl. VAT"; "Amount Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount including VAT for the whole document. The field may be filled automatically.';
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                }
            }
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Errors and Warnings';
                ShowFilter = false;
            }
        }
        area(factboxes)
        {
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
            }
            systempart(Control38; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control39; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(creation)
        {
        }
        area(navigation)
        {
            group(Action57)
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
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Data Exchange Types";
                    ToolTip = 'View the data exchange types that are available to convert electronic documents to documents in Dynamics 365.';
                }
                action(ActivityLog)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activity Log';
                    Image = Log;
                    ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                    trigger OnAction()
                    var
                        ActivityLog: Record "Activity Log";
                    begin
                        ActivityLog.ShowEntries(RecordId);
                    end;
                }
                action(OCRSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OCR Setup';
                    Image = ServiceSetup;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Open the OCR Service Setup window, for example to change credentials or enable the service.';
                    Visible = ShowOCRSetup;

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"OCR Service Setup");
                        CurrPage.Update;
                        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Web then
                            if OCRIsEnabled then begin
                                OnCloseIncomingDocumentFromAction(Rec);
                                CurrPage.Close;
                            end;
                    end;
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
        }
        area(processing)
        {
            action(CreateDocument)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Document';
                Enabled = AutomaticCreationActionsAreEnabled;
                Image = CreateDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create a document, such as a purchase invoice, automatically by converting the electronic document that is attached to the incoming document record.';

                trigger OnAction()
                begin
                    "Created Doc. Error Msg. Type" := "Created Doc. Error Msg. Type"::Warning;
                    Modify;
                    CreateDocumentWithDataExchange;
                end;
            }
            action(CreateGenJnlLine)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Journal Line';
                Enabled = AutomaticCreationActionsAreEnabled;
                Image = TransferToGeneralJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create a journal line automatically by converting the electronic document that is attached to the incoming document record.';

                trigger OnAction()
                begin
                    CreateGeneralJournalLineWithDataExchange;
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
                PromotedOnly = true;
                ToolTip = 'Create a document, such as a purchase invoice, manually from information in the file that is attached to the incoming document record.';

                trigger OnAction()
                begin
                    if not AskUserPermission then
                        exit;

                    CreateManually;
                end;
            }
            action(AttachFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attach File';
                Image = Attach;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Attach a file to the incoming document record.';

                trigger OnAction()
                begin
                    ImportAttachment(Rec);
                    CurrPage.Update(true);
                end;
            }
            action(ReplaceMainAttachment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Replace Main Attachment';
                Enabled = ReplaceMainAttachmentEnabled;
                Image = Interaction;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Attach another file to be used as the main file attachment on the incoming document record.';

                trigger OnAction()
                begin
                    ReplaceOrInsertMainAttachment;
                    Clear("Data Exchange Type");
                end;
            }
            action(AttachFromCamera)
            {
                ApplicationArea = All;
                Caption = 'Attach Image from Camera';
                Enabled = AttachEnabled;
                Image = Camera;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Add a picture from your device camera to the document.';
                Visible = HasCamera;

                trigger OnAction()
                var
                    IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    InStr: InStream;
                begin
                    if not HasCamera then
                        exit;

                    Camera.SetQuality(100); // 100%
                    Camera.RunModal();
                    if Camera.HasPicture() then begin
                        Camera.GetPicture(InStr);
                        AddAttachmentFromStream(IncomingDocumentAttachment, 'Incoming Document', '', InStr);
                    end;
                    Clear(Camera);
                end;
            }
            action(TextToAccountMapping)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Map Text to Account';
                Image = MapAccounts;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Text-to-Account Mapping Wksh.";
                ToolTip = 'Create a mapping of text on incoming documents to identical text on specific debit, credit, and balancing accounts in the general ledger or on bank accounts so that the resulting document or journal lines are prefilled with the specified information.';
            }
            group(Action45)
            {
                Caption = 'Release';
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Enabled = RecordHasAttachment;
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Release the incoming document to indicate that it has been approved by the incoming document approver.';

                    trigger OnAction()
                    var
                        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
                    begin
                        ReleaseIncomingDocument.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Enabled = RecordHasAttachment;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the incoming document record after it has been approved by the incoming document approver.';

                    trigger OnAction()
                    var
                        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
                    begin
                        ReleaseIncomingDocument.PerformManualReopen(Rec);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Enabled = RecordHasAttachment;
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Reject to approve the incoming document.';

                    trigger OnAction()
                    var
                        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
                    begin
                        ReleaseIncomingDocument.PerformManualReject(Rec);
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
                    Enabled = NOT Processed;
                    Image = Archive;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Set the incoming document to processed. It will then be moved to the Processed Incoming Documents window.';

                    trigger OnAction()
                    begin
                        Validate(Processed, true);
                        Modify(true);
                    end;
                }
                action(SetToUnprocessed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set To Unprocessed';
                    Enabled = Processed;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Set the incoming document to unprocessed. This allows you to edit information or perform actions for the incoming document.';

                    trigger OnAction()
                    begin
                        Validate(Processed, false);
                        Modify(true);
                    end;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        TestReadyForApproval;
                        ApprovalsMgmt.ApproveRecordApprovalRequest(RecordId);
                    end;
                }
                action(RejectApproval)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    ToolTip = 'Reject to approve the incoming document.';
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
                    PromotedCategory = Category8;
                    ToolTip = 'Delegate the approval to a substitute approver.';
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
                    PromotedCategory = Category8;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
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
                    PromotedCategory = Category9;
                    PromotedOnly = true;
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
                    Promoted = true;
                    PromotedCategory = Category9;
                    PromotedOnly = true;
                    ToolTip = 'Cancel requesting approval of the incoming document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelIncomingDocApprovalRequest(Rec);
                    end;
                }
            }
            group("Incoming Document")
            {
                Caption = 'Incoming Document';
                action(OpenDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Record';
                    Enabled = RecordLinkExists;
                    Image = ViewDetails;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    PromotedOnly = true;
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
                    Enabled = RecordLinkExists;
                    Image = ClearLog;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    PromotedOnly = true;
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
                    ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                    trigger OnAction()
                    var
                        NavigatePage: Page Navigate;
                    begin
                        if not Posted then
                            Error(NoPostedDocumentsErr);
                        NavigatePage.SetDoc("Posting Date", "Document No.");
                        NavigatePage.Run;
                    end;
                }
                group(Action51)
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
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        var
                            GenJournalBatch: Record "Gen. Journal Batch";
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            if not AskUserPermission then
                                exit;

                            CreateGenJnlLine;
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
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission then
                                exit;

                            CreatePurchInvoice;
                        end;
                    }
                    action(PurchaseCreditMemo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Credit Memo';
                        Image = CreditMemo;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission then
                                exit;

                            CreatePurchCreditMemo;
                        end;
                    }
                    action(SalesInvoice)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Invoice';
                        Image = Sales;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission then
                                exit;

                            CreateSalesInvoice;
                        end;
                    }
                    action(SalesCreditMemo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Credit Memo';
                        Image = CreditMemo;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission then
                                exit;

                            CreateSalesCreditMemo;
                        end;
                    }
                }
            }
            group(OCR)
            {
                Caption = 'OCR';
                action(SendToJobQueue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send to Job Queue';
                    Enabled = RecordHasAttachment;
                    Image = Translation;
                    ToolTip = 'Send the attached PDF or image file to the OCR service by the job queue according to the schedule, provided that no errors exist.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        SendToJobQueue(true);
                    end;
                }
                action(RemoveFromJobQueue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove from Job Queue';
                    Enabled = RecordHasAttachment;
                    Image = Translation;
                    ToolTip = 'Remove the scheduled processing of this record from the job queue.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        RemoveFromJobQueue(true);
                    end;
                }
                action(SendToOcr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send to OCR Service';
                    Enabled = CanBeSentToOCR;
                    Image = Translations;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Send the attached PDF or image file to the OCR service immediately.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        SendToOCR(true);
                    end;
                }
                action(ReceiveFromOCR)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receive from OCR Service';
                    Enabled = EnableReceiveFromOCR;
                    Image = Translations;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Get any electronic documents that are ready to receive from the OCR service.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        RetrieveFromOCR(true);
                    end;
                }
                action(CorrectOCRData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Correct OCR Data';
                    Enabled = OCRDataCorrectionEnabled;
                    Image = EditAttachment;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page "OCR Data Correction";
                    RunPageOnRec = true;
                    ToolTip = 'Open a window where you can teach the OCR service how to interpret data on PDF and image files so that future documents created by the OCR service are more correct.';
                    Visible = OCRServiceIsEnabled;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsDataExchTypeEditable := not (Status in [Status::Created, Status::Posted]);
        ShowErrors;
        SetCalculatedFields;
        RecordHasAttachment := HasAttachment;
        SetControlVisibility;
        AttachEnabled := "Entry No." <> 0;
    end;

    trigger OnAfterGetRecord()
    begin
        URL := GetURL;
        ShowErrors;
        EnableReceiveFromOCR := WaitingToReceiveFromOCR;
        CurrPage.Editable(not Processed);
    end;

    trigger OnInit()
    begin
        IsDataExchTypeEditable := true;
        EnableReceiveFromOCR := WaitingToReceiveFromOCR;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        AttachEnabled := true;
    end;

    trigger OnModifyRecord(): Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        OCRDataCorrectionEnabled := GetGeneratedFromOCRAttachment(IncomingDocumentAttachment);
        RecordHasAttachment := HasAttachment;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        URL := '';
    end;

    trigger OnOpenPage()
    begin
        HasCamera := Camera.IsAvailable();
        UpdateOCRSetupVisibility;
    end;

    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        AutomaticProcessingQst: Label 'The Data Exchange Type field is filled on at least one of the selected Incoming Documents.\\Are you sure you want to create documents manually?', Comment = '%1 is Data Exchange Type';
        ClientTypeManagement: Codeunit "Client Type Management";
        Camera: Page Camera;
        [InDataSet]
        HasCamera: Boolean;
        URL: Text;
        AttachmentFileName: Text;
        RecordLinkTxt: Text;
        OCRResultFileName: Text;
        IsDataExchTypeEditable: Boolean;
        OCRDataCorrectionEnabled: Boolean;
        AdditionalAttachmentsPresent: Boolean;
        InvalidTypeErr: Label 'The default attachment is not an XML document.';
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        EnableReceiveFromOCR: Boolean;
        CanCancelApprovalForRecord: Boolean;
        OCRServiceIsEnabled: Boolean;
        ShowOCRSetup: Boolean;
        AutomaticCreationActionsAreEnabled: Boolean;
        RecordHasAttachment: Boolean;
        RecordLinkExists: Boolean;
        NoPostedDocumentsErr: Label 'There are no posted documents.';
        CanBeSentToOCR: Boolean;
        AttachEnabled: Boolean;
        ReplaceMainAttachmentEnabled: Boolean;

    local procedure AskUserPermission(): Boolean
    begin
        if "Data Exchange Type" = '' then
            exit(true);

        if Status <> Status::New then
            exit(true);

        exit(Confirm(AutomaticProcessingQst));
    end;

    local procedure ShowErrors()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Context Record ID", RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update;
    end;

    local procedure SetCalculatedFields()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        OCRDataCorrectionEnabled := GetGeneratedFromOCRAttachment(IncomingDocumentAttachment);
        AttachmentFileName := GetMainAttachmentFileName;
        RecordLinkTxt := GetRecordLinkText;
        OCRResultFileName := GetOCRResutlFileName;
        AdditionalAttachmentsPresent := GetAdditionalAttachments(IncomingDocumentAttachment);
        if AdditionalAttachmentsPresent then
            CurrPage.SupportingAttachments.PAGE.LoadDataIntoPart(Rec);
    end;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RelatedRecord: Variant;
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
        UpdateOCRSetupVisibility;
        AutomaticCreationActionsAreEnabled := "Data Exchange Type" <> '';
        RecordLinkExists := GetRecord(RelatedRecord);
        CanBeSentToOCR := VerifyCanBeSentToOCR;
        ReplaceMainAttachmentEnabled := CanReplaceMainAttachment;
    end;

    [IntegrationEvent(TRUE, TRUE)]
    local procedure OnCloseIncomingDocumentFromAction(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    local procedure VerifyCanBeSentToOCR(): Boolean
    begin
        if not RecordHasAttachment then
            exit(false);

        exit(not ("OCR Status" in
                  ["OCR Status"::Sent, "OCR Status"::Success, "OCR Status"::"Awaiting Verification"]));
    end;

    local procedure UpdateOCRSetupVisibility()
    begin
        OCRServiceIsEnabled := OCRIsEnabled;
        ShowOCRSetup := not OCRServiceIsEnabled;
    end;
}

