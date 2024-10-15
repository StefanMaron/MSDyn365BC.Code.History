page 10752 "SII History"
{
    ApplicationArea = All;
    Caption = 'SII History';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Edit,Related Information';
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "SII History";
    SourceTableView = SORTING(Id)
                      ORDER(Descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("State ID"; "Document State Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the state ID.';
                    Visible = false;
                }
                field(Date; "Request Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the request date.';
                }
                field("Document Source"; SIIDocUploadState."Document Source")
                {
                    ApplicationArea = All;
                    Caption = 'Document Source';
                    Editable = false;
                    ToolTip = 'Specifies the document source.';
                }
                field("Document Type"; SIIDocUploadState."Document Type")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the document type.';
                }
                field("Document No."; SIIDocUploadState."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the Document No.';
                }
                field(CVNo; SIIDocUploadState."CV No.")
                {
                    ApplicationArea = All;
                    Caption = 'Customer/Vendor No.';
                    ToolTip = 'Specifies the customer/vendor no. of the entry.';
                }
                field("Posting Date"; SIIDocUploadState."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date.';
                }
                field(SalesInvType; SIIDocUploadState."Sales Invoice Type")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Invoice Type';
                    ToolTip = 'Specifies the type of the sales invoice.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Invoice Type"));
                    end;
                }
                field(SalesCrMemoType; SIIDocUploadState."Sales Cr. Memo Type")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Cr. Memo Type';
                    ToolTip = 'Specifies the type of the sales credit memo.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Cr. Memo Type"));
                    end;
                }
                field(SalesSpecialSchemeCode; SIIDocUploadState."Sales Special Scheme Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Special Scheme Code';
                    Editable = false;
                    ToolTip = 'Specifies the special scheme code of the sales document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Special Scheme Code"));
                    end;
                }
                field(PurchInvType; SIIDocUploadState."Purch. Invoice Type")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Invoice Type';
                    ToolTip = 'Specifies the type of the purchase invoice.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Purch. Invoice Type"));
                    end;
                }
                field(PurchCrMemoType; SIIDocUploadState."Purch. Cr. Memo Type")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Cr. Memo Type';
                    ToolTip = 'Specifies the type of the purchase credit memo.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Purch. Cr. Memo Type"));
                    end;
                }
                field(PurchSpecialSchemeCode; SIIDocUploadState."Purch. Special Scheme Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Special Scheme Code';
                    Editable = false;
                    ToolTip = 'Specifies the special scheme code of the purchase document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Purch. Special Scheme Code"));
                    end;
                }
                field(RetryAccepted; SIIDocUploadState."Retry Accepted")
                {
                    ApplicationArea = All;
                    Caption = 'Retry Accepted';
                    ToolTip = 'Specifies if the already accepted entry to be send to SII system again.';
                }
                field(SucceededCompanyName; SIIDocUploadState."Succeeded Company Name")
                {
                    ApplicationArea = All;
                    Caption = 'Succeeded Company Name';
                    ToolTip = 'Specifies the name of the company sucessor in connection with corporate restructuring.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo("Succeeded Company Name"));
                    end;
                }
                field(SucceededVATRegistrationNo; SIIDocUploadState."Succeeded VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'Succeeded VAT Registration No.';
                    ToolTip = 'Specifies the VAT registration number of the company sucessor in connection with corporate restructuring.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo("Succeeded VAT Registration No."));
                    end;
                }
                field(SIIVersionNo; SIIDocUploadState."Version No.")
                {
                    ApplicationArea = All;
                    Caption = 'SII Version No.';
                    ToolTip = 'Specifies which version of the immediate VAT information system is used.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo("Version No."));
                    end;
                }
                field(IDType; SIIDocUploadState.IDType)
                {
                    ApplicationArea = All;
                    Caption = 'ID Type';
                    ToolTip = 'Specifies which ID type of the immediate VAT information system is used.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo(IDType));
                    end;
                }
                field(AcceptedByUserID; SIIDocUploadState."Accepted By User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Accepted By User ID';
                    ToolTip = 'Specifies the user who manually change the status to Accepted by action Mark As Accepted.';
                    Visible = false;
                }
                field(AcceptedDateTime; SIIDocUploadState."Accepted Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'Accepted Date Time';
                    ToolTip = 'Specifies the date and time when user change the status to Accepted by action Mark As Accepted.';
                    Visible = false;
                }
                field("Upload Type"; "Upload Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the upload Type.';
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the status.';
                }
                field("Error Message"; "Error Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the error Message.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Retry)
            {
                ApplicationArea = All;
                Caption = 'Retry';
                Enabled = Enabled;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Retry to send the document to SII.';
                Visible = RecordsFound;

                trigger OnAction()
                begin
                    IssueManualRequest(false);
                end;
            }
            action("Retry All")
            {
                ApplicationArea = All;
                Caption = 'Retry All';
                Enabled = EnabledBatchSubmission;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Retry to send all non-accepted documents to SII.';

                trigger OnAction()
                begin
                    RetryAllRequests;
                end;
            }
            action("Retry Accepted")
            {
                ApplicationArea = All;
                Caption = 'Retry Accepted';
                Enabled = Enabled;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Retry to send accepted documents to SII.';

                trigger OnAction()
                begin
                    if Confirm(RetryAcceptedQst) then
                        IssueManualRequest(true);
                end;
            }
            action("Generate Collections In Cash")
            {
                ApplicationArea = All;
                Caption = 'Generate Collections In Cash';
                Enabled = Enabled;
                Image = CreateLinesFromJob;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;

                trigger OnAction()
                var
                    SIIManagement: Codeunit "SII Management";
                begin
                    SIIManagement.Run347DeclarationToGenerateCollectionsInCash;
                    CurrPage.Update();
                end;
            }
            action("Mark As Accepted")
            {
                ApplicationArea = All;
                Caption = 'Mark As Accepted';
                Enabled = Enabled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Mark as accepted. A new pending entry will be created.';
                Visible = ShowAdvancedActions;

                trigger OnAction()
                begin
                    MarkAsAccepted;
                end;
            }
            action("Mark As Not Accepted")
            {
                ApplicationArea = All;
                Caption = 'Mark As Not Accepted';
                Enabled = Enabled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Mark as not accepted. A new pending entry will be created.';
                Visible = ShowAdvancedActions;

                trigger OnAction()
                begin
                    MarkAsNotAccepted;
                end;
            }
            action("Recreate Missing SII Entries")
            {
                ApplicationArea = All;
                Caption = 'Recreate Missing SII Entries';
                Enabled = Enabled;
                Image = CreateLinesFromTimesheet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Recreate Missing SII Entries";
                Scope = Repeater;
                ToolTip = 'Recreate missing SII entries manually.';
                Visible = ShowAdvancedActions;
            }
        }
        area(navigation)
        {
            action("&Navigate")
            {
                ApplicationArea = All;
                Caption = 'Find entries...';
                Enabled = RecordsFound;
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc(SIIDocUploadState."Posting Date", CopyStr(SIIDocUploadState."Document No.", 1, 20));
                    Navigate.Run();
                end;
            }
            action(ShowRequest)
            {
                ApplicationArea = All;
                Caption = 'Show Request XML';
                Enabled = HasRequestXML;
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Displays the XML sent to the web service as a message.';

                trigger OnAction()
                var
                    SIISession: Record "SII Session";
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                    FileName: Text;
                begin
                    FileName := FileManagement.ServerTempFileName('xml');
                    SIISession.Get("Session Id");
                    SIISession.CalcFields("Request XML");
                    TempBlob.FromRecord(SIISession, SIISession.FieldNo("Request XML"));
                    FileManagement.BLOBExportWithEncoding(TempBlob, FileName, true, TEXTENCODING::UTF8);
                end;
            }
            action(ShowResponse)
            {
                ApplicationArea = All;
                Caption = 'Show Response XML';
                Enabled = HasResponseXML;
                Image = Receipt;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Displays the response received from the web service as a message.';

                trigger OnAction()
                var
                    SIISession: Record "SII Session";
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                    FileName: Text;
                begin
                    FileName := FileManagement.ServerTempFileName('xml');
                    SIISession.Get("Session Id");
                    SIISession.CalcFields("Response XML");
                    TempBlob.FromRecord(SIISession, SIISession.FieldNo("Response XML"));
                    FileManagement.BLOBExportWithEncoding(TempBlob, FileName, true, TEXTENCODING::UTF8);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        SIISession: Record "SII Session";
    begin
        if SIISession.Get("Session Id") then begin
            HasRequestXML := SIISession."Request XML".HasValue;
            HasResponseXML := SIISession."Response XML".HasValue;
        end else begin
            HasRequestXML := false;
            HasResponseXML := false;
        end;
    end;

    trigger OnAfterGetRecord()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        RecordsFound := true;
        StyleText := SIIManagement.GetSIIStyle(Status.AsInteger());
        SIIDocUploadState.Get("Document State Id");
    end;

    trigger OnInit()
    var
        SIISetup: Record "SII Setup";
        SIIJobManagement: Codeunit "SII Job Management";
    begin
        if SIISetup.Get then begin
            Enabled := SIISetup.Enabled;
            EnabledBatchSubmission := Enabled and SIISetup."Enable Batch Submissions";
            ShowAdvancedActions := SIISetup."Show Advanced Actions";
        end else begin
            Enabled := false;
            EnabledBatchSubmission := false;
            ShowAdvancedActions := false;
        end;
        SIIJobManagement.CreateAndStartJobQueueEntryForMissingEntryDetection(SIISetup."Auto Missing Entries Check");
    end;

    trigger OnOpenPage()
    begin
        if FindFirst() then;
    end;

    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        [InDataSet]
        RecordsFound: Boolean;
        [InDataSet]
        HasRequestXML: Boolean;
        [InDataSet]
        HasResponseXML: Boolean;
        [InDataSet]
        StyleText: Text;
        Enabled: Boolean;
        EnabledBatchSubmission: Boolean;
        RetryAcceptedQst: Label 'Accepted entries have been selected. Do you want to resend them?';
        ShowAdvancedActions: Boolean;

    local procedure IssueManualRequest(RetryAccepted: Boolean)
    var
        SIIHistory: Record "SII History";
        TempSIIDocUploadState: Record "SII Doc. Upload State" temporary;
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
    begin
        if EnabledBatchSubmission then
            CurrPage.SetSelectionFilter(SIIHistory)
        else begin
            SIIHistory := Rec;
            SIIHistory.SetRecFilter;
        end;

        with SIIHistory do begin
            Ascending(false);
            if RetryAccepted then
                SetRange(Status, Status::Accepted)
            else
                SetFilter(Status, '<>%1', Status::Accepted);

            if FindSet(true) then
                repeat
                    CreateNewRequestPerDocument(
                      TempSIIDocUploadState, SIIHistory, "Upload Type", RetryAccepted or (Status = Status::"Accepted With Errors"));
                until Next() = 0;
        end;
        SIIDocUploadManagement.UploadManualDocument;
    end;

    local procedure RetryAllRequests()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
    begin
        SIIDocUploadState.SetFilter(Status, '<>%1', Status::Accepted);
        if SIIDocUploadState.FindSet(true) then begin
            SIIHistory.Ascending(false);
            repeat
                SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                if SIIHistory.FindFirst() then
                    if SIIHistory.Status <> SIIHistory.Status::Pending then
                        CreateNewRequest(
                          SIIHistory."Document State Id", SIIHistory."Upload Type", 1, true,
                          SIIHistory.Status = SIIHistory.Status::"Accepted With Errors")
                    else
                        if not SIIHistory."Is Manual" then begin
                            SIIHistory."Is Manual" := true;
                            SIIHistory.Modify();
                            SIIDocUploadState."Is Manual" := true;
                            SIIDocUploadState.Modify();
                        end;
            until SIIDocUploadState.Next() = 0;
        end;
        SIIDocUploadManagement.UploadManualDocument
    end;

    local procedure CreateNewRequestPerDocument(var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; var SIIHistory: Record "SII History"; UploadType: Option; IsAcceptedWithErrorRetry: Boolean)
    begin
        with SIIHistory do
            if not TempSIIDocUploadState.Get("Document State Id") then begin
                TempSIIDocUploadState.Id := "Document State Id";
                TempSIIDocUploadState.Insert();

                if Status <> Status::Pending then
                    // We set 1 retry for manual call.
                    CreateNewRequest("Document State Id", UploadType, 1, true, IsAcceptedWithErrorRetry)
                else
                    if not "Is Manual" and (Status <> Status::Accepted) then begin
                        "Is Manual" := true;
                        Modify;
                        SIIDocUploadState.Get("Document State Id");
                        SIIDocUploadState."Is Manual" := true;
                        SIIDocUploadState.Modify();
                    end;
            end;
    end;
}

