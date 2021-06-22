codeunit 5980 "Service-Post"
{
    Permissions = TableData "Service Header" = imd,
                  TableData "Service Item Line" = imd,
                  TableData "Service Line" = imd,
                  TableData "Service Shipment Item Line" = imd,
                  TableData "Service Shipment Header" = imd,
                  TableData "Service Shipment Line" = imd,
                  TableData "Service Invoice Header" = imd,
                  TableData "Service Invoice Line" = imd,
                  TableData "Service Cr.Memo Header" = imd,
                  TableData "Service Cr.Memo Line" = imd;
    TableNo = "Service Header";

    trigger OnRun()
    var
        DummyServLine: Record "Service Line" temporary;
    begin
        OnBeforeRun(Rec);

        PostWithLines(Rec, DummyServLine, Ship, Consume, Invoice);
    end;

    var
        ServiceShptLine: Record "Service Shipment Line";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        ServiceSetup: Record "Service Mgt. Setup";
        ServiceInvLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        ServDocumentsMgt: Codeunit "Serv-Documents Mgt.";
        WhsePostShpt: Codeunit "Whse.-Post Shipment";
        Window: Dialog;
        PostingDate: Date;
        ReplaceDocumentDate: Boolean;
        ReplacePostingDate: Boolean;
        PostingDateExists: Boolean;
        HideValidationDialog: Boolean;
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
        Text001: Label 'There is nothing to post.';
        Text002: Label 'Posting lines              #2######\';
        Text003: Label 'Posting serv. and VAT      #3######\';
        Text004: Label 'Posting to customers       #4######\';
        Text005: Label 'Posting to bal. account    #5######';
        Text006: Label 'Posting lines              #2######';
        Text007: Label 'is not within your range of allowed posting dates';
        WhseShip: Boolean;
        PreviewMode: Boolean;
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1=Document Type e.g. Invoice';

    procedure PostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        GLEntry: Record "G/L Entry";
        ServDocReg: Record "Service Document Register";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        WarehouseShipmentHeaderLocal: Record "Warehouse Shipment Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        WhseServiceRelease: Codeunit "Whse.-Service Release";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ServDocNo: Code[20];
        ServDocType: Integer;
        ServInvoiceNo: Code[20];
        ServCrMemoNo: Code[20];
        ServShipmentNo: Code[20];
    begin
        OnBeforePostWithLines(PassedServHeader, PassedServLine, PassedShip, PassedConsume, PassedInvoice);

        ServiceHeader := PassedServHeader;

        Clear(ServDocumentsMgt);

        ValidatePostingAndDocumentDate(ServiceHeader);

        Initialize(ServiceHeader, PassedServLine, PassedShip, PassedConsume, PassedInvoice);

        with ServiceHeader do begin
            if Invoice then
                Window.Open('#1#################################\\' + Text002 + Text003 + Text004 + Text005)
            else
                Window.Open('#1#################################\\' + Text006);
            Window.Update(1, StrSubstNo('%1 %2', "Document Type", "No."));

            if ServDocumentsMgt.SetNoSeries(ServiceHeader) then
                Modify;

            ServDocumentsMgt.CalcInvDiscount;
            Find;

            CollectWhseShipmentInformation(PassedServHeader);

            LockTables(ServiceLine, GLEntry);

            // fetch related document (if any), for testing invoices and credit memos fields.
            Clear(ServDocReg);
            ServDocReg.ServiceDocument("Document Type", "No.", ServDocType, ServDocNo);

            // update quantites upon posting options and test related fields.
            ServDocumentsMgt.CheckAndBlankQtys(ServDocType);

            // create posted documents (both header and lines).
            WhseShip := false;
            if Ship then begin
                ServShipmentNo := ServDocumentsMgt.PrepareShipmentHeader;
                WhseShip := not TempWarehouseShipmentHeader.IsEmpty;
            end;
            if Invoice then
                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                    ServInvoiceNo := ServDocumentsMgt.PrepareInvoiceHeader(Window)
                else
                    ServCrMemoNo := ServDocumentsMgt.PrepareCrMemoHeader(Window);

            if WhseShip then begin
                WarehouseShipmentHeader.Get(TempWarehouseShipmentHeader."No.");
                OnBeforeCreatePostedWhseShptHeader(PostedWhseShipmentHeader, WarehouseShipmentHeader, ServiceHeader);
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShipmentHeader, WarehouseShipmentHeader, "Shipping No.", "Posting Date");
            end;

            // main lines posting routine via Journals
            ServDocumentsMgt.PostDocumentLines(Window);
            ServDocumentsMgt.CollectTrackingSpecification(TempTrackingSpecification);

            ServDocumentsMgt.SetLastNos(ServiceHeader);
            Modify;

            // handling afterposting modification/deletion of documents
            ServDocumentsMgt.UpdateDocumentLines;

            ServDocumentsMgt.InsertValueEntryRelation;

            if WhseShip then begin
                if TempWarehouseShipmentLine.FindSet then
                    repeat
                        WarehouseShipmentLine.Get(TempWarehouseShipmentLine."No.", TempWarehouseShipmentLine."Line No.");
                        WhsePostShpt.CreatePostedShptLine(WarehouseShipmentLine, PostedWhseShipmentHeader,
                          PostedWhseShipmentLine, TempTrackingSpecification);
                    until TempWarehouseShipmentLine.Next = 0;
                if WarehouseShipmentHeaderLocal.Get(WarehouseShipmentHeader."No.") then
                    WhsePostShpt.PostUpdateWhseDocuments(WarehouseShipmentHeader);
            end;

            if PreviewMode then begin
                Window.Close;
                GenJnlPostPreview.ThrowError;
            end;

            Finalize(ServiceHeader);

            OnAfterFinalizePostingOnBeforeCommit(
              PassedServHeader, PassedServLine, ServDocumentsMgt, PassedShip, PassedConsume, PassedInvoice);
        end;

        if WhseShip then
            WhseServiceRelease.Release(ServiceHeader);
        Commit();

        OnAfterPostServiceDoc(ServiceHeader, ServShipmentNo, ServInvoiceNo, ServCrMemoNo);

        Window.Close;
        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);

        PassedServHeader := ServiceHeader;

        OnAfterPostWithLines(PassedServHeader);
    end;

    local procedure Initialize(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        OnBeforeInitialize(PassedServiceHeader, PassedServiceLine, PassedShip, PassedConsume, PassedInvoice, PreviewMode);

        SetPostingOptions(PassedShip, PassedConsume, PassedInvoice);
        TestMandatoryFields(PassedServiceHeader, PassedServiceLine);
        ReportDistributionManagement.RunDefaultCheckServiceElectronicDocument(PassedServiceHeader);
        ServDocumentsMgt.Initialize(PassedServiceHeader, PassedServiceLine);

        // Also calls procedure of the same name from ServDocMgt.
        // Might change the value of global Ship,Consume,Invoice vars.
        CheckAndSetPostingConstants(PassedServiceHeader, PassedShip, PassedConsume, PassedInvoice);

        // check for service lines with adjusted price
        if (not HideValidationDialog or not GuiAllowed) and
           Invoice and (PassedServiceHeader."Document Type" = PassedServiceHeader."Document Type"::Order)
        then
            ServDocumentsMgt.CheckAdjustedLines;

        OnAfterInitialize(PassedServiceHeader, PassedServiceLine);
    end;

    local procedure Finalize(var PassedServiceHeader: Record "Service Header")
    begin
        ServDocumentsMgt.Finalize(PassedServiceHeader);
    end;

    local procedure CheckAndSetPostingConstants(var ServiceHeader: Record "Service Header"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
        with ServiceHeader do begin
            case "Document Type" of
                "Document Type"::Invoice:
                    begin
                        PassedShip := true;
                        PassedInvoice := true;
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        PassedShip := false;
                        PassedInvoice := true;
                    end;
            end;

            ServDocumentsMgt.CheckAndSetPostingConstants(PassedShip, PassedConsume, PassedInvoice);

            if not (PassedShip or PassedInvoice or PassedConsume) then
                Error(Text001);

            if Invoice and ("Document Type" <> "Document Type"::"Credit Memo") then
                TestField("Due Date");
        end;
        SetPostingOptions(PassedShip, PassedConsume, PassedInvoice);
    end;

    local procedure ValidatePostingAndDocumentDate(var ServiceHeader: Record "Service Header")
    begin
        if PostingDateExists and (ReplacePostingDate or (ServiceHeader."Posting Date" = 0D)) then begin
            ServiceHeader.Validate("Posting Date", PostingDate);
            ServiceHeader.Validate("Currency Code");
        end;
        if PostingDateExists and (ReplaceDocumentDate or (ServiceHeader."Document Date" = 0D)) then
            ServiceHeader.Validate("Document Date", PostingDate);

        OnAfterValidatePostingAndDocumentDate(ServiceHeader, PreviewMode);
    end;

    local procedure TestMandatoryFields(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        with PassedServiceHeader do begin
            TestField("Document Type");
            TestField("Customer No.");
            TestField("Bill-to Customer No.");
            TestField("Posting Date");
            TestField("Document Date");
            if PassedServiceLine.IsEmpty then
                TestServLinePostingDate("Document Type", "No.")
            else
                if "Posting Date" <> PassedServiceLine."Posting Date" then begin
                    if PassedServiceLine.Type <> PassedServiceLine.Type::" " then
                        if GenJnlCheckLine.DateNotAllowed(PassedServiceLine."Posting Date") then
                            PassedServiceLine.FieldError("Posting Date", Text007);

                    if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                        FieldError("Posting Date", Text007);
                end;
            TestMandatoryFields(PassedServiceLine);
        end;
    end;

    procedure SetPostingDate(NewReplacePostingDate: Boolean; NewReplaceDocumentDate: Boolean; NewPostingDate: Date)
    begin
        ClearAll;
        PostingDateExists := true;
        ReplacePostingDate := NewReplacePostingDate;
        ReplaceDocumentDate := NewReplaceDocumentDate;
        PostingDate := NewPostingDate;
    end;

    procedure SetPostingOptions(PassedShip: Boolean; PassedConsume: Boolean; PassedInvoice: Boolean)
    begin
        Ship := PassedShip;
        Consume := PassedConsume;
        Invoice := PassedInvoice;
        ServDocumentsMgt.SetPostingOptions(Ship, Consume, Invoice);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure TestDeleteHeader(ServiceHeader: Record "Service Header"; var ServiceShptHeader: Record "Service Shipment Header"; var ServiceInvHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        with ServiceHeader do begin
            Clear(ServiceShptHeader);
            Clear(ServiceInvHeader);
            Clear(ServiceCrMemoHeader);
            ServiceSetup.Get();

            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Deleted Document");
            SourceCode.Get(SourceCodeSetup."Deleted Document");

            if ("Shipping No. Series" <> '') and ("Shipping No." <> '') then begin
                ServiceShptHeader.TransferFields(ServiceHeader);
                ServiceShptHeader."No." := "Shipping No.";
                ServiceShptHeader."Posting Date" := Today;
                ServiceShptHeader."User ID" := UserId;
                ServiceShptHeader."Source Code" := SourceCode.Code;
            end;

            if ("Posting No. Series" <> '') and
               (("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) and
                ("Posting No." <> '') or
                ("Document Type" = "Document Type"::Invoice) and
                ("No. Series" = "Posting No. Series"))
            then begin
                ServiceInvHeader.TransferFields(ServiceHeader);
                if "Posting No." <> '' then
                    ServiceInvHeader."No." := "Posting No.";
                if "Document Type" = "Document Type"::Invoice then begin
                    ServiceInvHeader."Pre-Assigned No. Series" := "No. Series";
                    ServiceInvHeader."Pre-Assigned No." := "No.";
                end else begin
                    ServiceInvHeader."Pre-Assigned No. Series" := '';
                    ServiceInvHeader."Pre-Assigned No." := '';
                    ServiceInvHeader."Order No. Series" := "No. Series";
                    ServiceInvHeader."Order No." := "No.";
                end;
                ServiceInvHeader."Posting Date" := Today;
                ServiceInvHeader."User ID" := UserId;
                ServiceInvHeader."Source Code" := SourceCode.Code;
            end;

            if ("Posting No. Series" <> '') and
               (("Document Type" in ["Document Type"::"Credit Memo"]) and
                ("Posting No." <> '') or
                ("Document Type" = "Document Type"::"Credit Memo") and
                ("No. Series" = "Posting No. Series"))
            then begin
                ServiceCrMemoHeader.TransferFields(ServiceHeader);
                if "Posting No." <> '' then
                    ServiceCrMemoHeader."No." := "Posting No.";
                ServiceCrMemoHeader."Pre-Assigned No. Series" := "No. Series";
                ServiceCrMemoHeader."Pre-Assigned No." := "No.";
                ServiceCrMemoHeader."Posting Date" := Today;
                ServiceCrMemoHeader."User ID" := UserId;
                ServiceCrMemoHeader."Source Code" := SourceCode.Code;
            end;
        end;
    end;

    local procedure LockTables(var ServiceLine: Record "Service Line"; var GLEntry: Record "G/L Entry")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        ServiceLine.LockTable();

        GLSetup.Get();
        if not GLSetup.OptimGLEntLockForMultiuserEnv then begin
            GLEntry.LockTable();
            if GLEntry.Find('+') then;
        end;
    end;

    procedure DeleteHeader(ServiceHeader: Record "Service Header"; var ServiceShptHeader: Record "Service Shipment Header"; var ServiceInvHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        with ServiceHeader do begin
            TestDeleteHeader(ServiceHeader, ServiceShptHeader, ServiceInvHeader, ServiceCrMemoHeader);
            if ServiceShptHeader."No." <> '' then begin
                OnBeforeServiceShptHeaderInsert(ServiceShptHeader, ServiceHeader);
                ServiceShptHeader.Insert();
                ServiceShptLine.Init();
                ServiceShptLine."Document No." := ServiceShptHeader."No.";
                ServiceShptLine."Line No." := 10000;
                ServiceShptLine.Description := SourceCode.Description;
                ServiceShptLine.Insert();
            end;

            if ServiceInvHeader."No." <> '' then begin
                OnBeforeServiceInvHeaderInsert(ServiceInvHeader, ServiceHeader);
                ServiceInvHeader.Insert();
                ServiceInvLine.Init();
                ServiceInvLine."Document No." := ServiceInvHeader."No.";
                ServiceInvLine."Line No." := 10000;
                ServiceInvLine.Description := SourceCode.Description;
                ServiceInvLine.Insert();
            end;

            if ServiceCrMemoHeader."No." <> '' then begin
                OnBeforeServiceCrMemoHeaderInsert(ServiceCrMemoHeader, ServiceHeader);
                ServiceCrMemoHeader.Insert();
                ServiceCrMemoLine.Init();
                ServiceCrMemoLine."Document No." := ServiceCrMemoHeader."No.";
                ServiceCrMemoLine."Line No." := 10000;
                ServiceCrMemoLine.Description := SourceCode.Description;
                ServiceCrMemoLine.Insert();
            end;
        end;
    end;

    local procedure CollectWhseShipmentInformation(ServiceHeader: Record "Service Header")
    var
        WarehouseShipmentHeaderLocal: Record "Warehouse Shipment Header";
        WarehouseShipmentLineLocal: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
    begin
        TempWarehouseShipmentHeader.DeleteAll();
        TempWarehouseShipmentLine.DeleteAll();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("Qty. to Ship", '<>%1', 0);
        if not ServiceLine.FindSet then
            exit;
        WarehouseShipmentLineLocal.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLineLocal.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLineLocal.SetRange("Source Subtype", ServiceHeader."Document Type");
        WarehouseShipmentLineLocal.SetRange("Source No.", ServiceHeader."No.");
        repeat
            WarehouseShipmentLineLocal.SetRange("Source Line No.", ServiceLine."Line No.");
            if WarehouseShipmentLineLocal.FindSet then
                repeat
                    if WarehouseShipmentLineLocal."Qty. to Ship" <> 0 then begin
                        TempWarehouseShipmentLine := WarehouseShipmentLineLocal;
                        TempWarehouseShipmentLine.Insert();
                        WarehouseShipmentHeaderLocal.Get(WarehouseShipmentLineLocal."No.");
                        TempWarehouseShipmentHeader := WarehouseShipmentHeaderLocal;
                        if TempWarehouseShipmentHeader.Insert() then;
                    end;
                until WarehouseShipmentLineLocal.Next = 0;
        until ServiceLine.Next = 0;
    end;

    local procedure TestServLinePostingDate(ServHeaderDocType: Integer; ServHeaderNo: Code[20])
    var
        ServLine: Record "Service Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        with ServLine do begin
            SetRange("Document Type", ServHeaderDocType);
            SetRange("Document No.", ServHeaderNo);
            SetFilter(Type, '<>%1', Type::" ");
            if FindSet then
                repeat
                    if GenJnlCheckLine.DateNotAllowed("Posting Date") then
                        FieldError("Posting Date", Text007)
                until Next = 0;
        end;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    procedure GetPostedDocumentRecord(ServiceHeader: Record "Service Header"; var PostedServiceDocumentVariant: Variant)
    var
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        with ServiceHeader do
            case "Document Type" of
                "Document Type"::Order:
                    if Invoice then begin
                        ServiceInvHeader.Get("Last Posting No.");
                        ServiceInvHeader.SetRecFilter;
                        PostedServiceDocumentVariant := ServiceInvHeader;
                    end;
                "Document Type"::Invoice:
                    begin
                        if "Last Posting No." = '' then
                            ServiceInvHeader.Get("No.")
                        else
                            ServiceInvHeader.Get("Last Posting No.");

                        ServiceInvHeader.SetRecFilter;
                        PostedServiceDocumentVariant := ServiceInvHeader;
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if "Last Posting No." = '' then
                            ServiceCrMemoHeader.Get("No.")
                        else
                            ServiceCrMemoHeader.Get("Last Posting No.");
                        ServiceCrMemoHeader.SetRecFilter;
                        PostedServiceDocumentVariant := ServiceCrMemoHeader;
                    end;
                else
                    Error(NotSupportedDocumentTypeErr, "Document Type");
            end;
    end;

    [Scope('OnPrem')]
    procedure SendPostedDocumentRecord(ServiceHeader: Record "Service Header"; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        with ServiceHeader do
            case "Document Type" of
                "Document Type"::Order:
                    if Invoice then begin
                        ServiceInvHeader.Get("Last Posting No.");
                        ServiceInvHeader.SetRecFilter;
                        ServiceInvHeader.SendProfile(DocumentSendingProfile);
                    end;
                "Document Type"::Invoice:
                    begin
                        if "Last Posting No." = '' then
                            ServiceInvHeader.Get("No.")
                        else
                            ServiceInvHeader.Get("Last Posting No.");

                        ServiceInvHeader.SetRecFilter;
                        ServiceInvHeader.SendProfile(DocumentSendingProfile);
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if "Last Posting No." = '' then
                            ServiceCrMemoHeader.Get("No.")
                        else
                            ServiceCrMemoHeader.Get("Last Posting No.");
                        ServiceCrMemoHeader.SetRecFilter;
                        ServiceCrMemoHeader.SendProfile(DocumentSendingProfile);
                    end;
                else
                    Error(NotSupportedDocumentTypeErr, "Document Type");
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServDocumentsMgt: Codeunit "Serv-Documents Mgt."; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostServiceDoc(var ServiceHeader: Record "Service Header"; ServShipmentNo: Code[20]; ServInvoiceNo: Code[20]; ServCrMemoNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWithLines(var PassedServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostingAndDocumentDate(var ServiceHeader: Record "Service Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedWhseShptHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptHeaderInsert(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoHeaderInsert(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    begin
    end;
}

