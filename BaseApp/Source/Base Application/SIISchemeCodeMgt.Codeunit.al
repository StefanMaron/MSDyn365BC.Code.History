codeunit 10758 "SII Scheme Code Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure GetMaxNumberOfRegimeCodes(): Integer
    var
    begin
        exit(3);
    end;
	
    procedure SalesDocHasRegimeCodes(RecVar: Variant): Boolean
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        if not GetSIISalesDocRecFromRec(SIISalesDocumentSchemeCode, RecVar) then
            exit(false);
        exit(not SIISalesDocumentSchemeCode.IsEmpty());
    end;

    procedure SalesDrillDownRegimeCodes(RecVar: Variant)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        if GetSIISalesDocRecFromRec(SIISalesDocumentSchemeCode, RecVar) then
            PAGE.RunModal(0, SIISalesDocumentSchemeCode);
    end;

    local procedure GetSIISalesDocRecFromRec(var SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code"; RecVar: Variant): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SalesHeader."Document Type");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesHeader."No.");
                    exit(true);
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesInvoiceHeader."No.");
                    exit(true);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesCrMemoHeader."No.");
                    exit(true);
                end;
            DATABASE::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", ServiceHeader."Document Type");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceHeader."No.");
                    exit(true);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServiceInvoiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceInvoiceHeader."No.");
                    exit(true);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServiceCrMemoHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceCrMemoHeader."No.");
                    exit(true);
                end;
        end;
    end;

    local procedure MoveSalesRegimeCodesToPostedDoc(DocType: Option; DocNo: Code[20]; EntryType: Option; PostedDocType: Option; PostedDocNo: Code[20])
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        NewSIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        SIISalesDocumentSchemeCode.SetRange("Entry Type", EntryType);
        SIISalesDocumentSchemeCode.SetRange("Document Type", DocType);
        SIISalesDocumentSchemeCode.SetRange("Document No.", DocNo);
        if not SIISalesDocumentSchemeCode.FindSet() then
            exit;

        repeat
            NewSIISalesDocumentSchemeCode := SIISalesDocumentSchemeCode;
            NewSIISalesDocumentSchemeCode."Document Type" := PostedDocType;
            NewSIISalesDocumentSchemeCode."Document No." := PostedDocNo;
            NewSIISalesDocumentSchemeCode.Insert();
        until SIISalesDocumentSchemeCode.Next() = 0;
        SIISalesDocumentSchemeCode.DeleteAll(true);
    end;

    procedure PurchDocHasRegimeCodes(RecVar: Variant): Boolean
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        if not GetSIIPurchDocRecFromRec(SIIPurchDocSchemeCode, RecVar) then
            exit(false);
        exit(not SIIPurchDocSchemeCode.IsEmpty());
    end;

    procedure PurchDrillDownRegimeCodes(RecVar: Variant)
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        if GetSIIPurchDocRecFromRec(SIIPurchDocSchemeCode, RecVar) then
            PAGE.RunModal(0, SIIPurchDocSchemeCode);
    end;

    local procedure GetSIIPurchDocRecFromRec(var SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code"; RecVar: Variant): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    SIIPurchDocSchemeCode.SetRange("Document Type", PurchaseHeader."Document Type");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchaseHeader."No.");
                    exit(true);
                end;
            DATABASE::"Purch. Inv. Header":
                begin
                    RecRef.SetTable(PurchInvHeader);
                    SIIPurchDocSchemeCode.SetRange("Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Invoice");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchInvHeader."No.");
                    exit(true);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.SetTable(PurchCrMemoHdr);
                    SIIPurchDocSchemeCode.SetRange("Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchCrMemoHdr."No.");
                    exit(true);
                end;
        end;
    end;

    local procedure MovePurchRegimeCodesToPostedDoc(PurchaseHeader: Record "Purchase Header"; PostedDocType: Option; PostedDocNo: Code[20])
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        NewSIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        SIIPurchDocSchemeCode.SetRange("Document Type", PurchaseHeader."Document Type");
        SIIPurchDocSchemeCode.SetRange("Document No.", PurchaseHeader."No.");
        if not SIIPurchDocSchemeCode.FindSet() then
            exit;

        repeat
            NewSIIPurchDocSchemeCode := SIIPurchDocSchemeCode;
            NewSIIPurchDocSchemeCode."Document Type" := PostedDocType;
            NewSIIPurchDocSchemeCode."Document No." := PostedDocNo;
            NewSIIPurchDocSchemeCode.Insert();
        until SIIPurchDocSchemeCode.Next() = 0;
        SIIPurchDocSchemeCode.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          SalesHeader."Document Type", SalesHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Sales,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice", SalesInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          SalesHeader."Document Type", SalesHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Sales,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo", SalesCrMemoHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 5988, 'OnAfterServInvHeaderInsert', '', false, false)]
    local procedure OnAfterServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          ServiceHeader."Document Type", ServiceHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Service,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice", ServiceInvoiceHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 5988, 'OnAfterServCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterServCrMemoHeaderInsert(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          ServiceHeader."Document Type", ServiceHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Service,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo", ServiceCrMemoHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, 'OnAfterPurchInvHeaderInsert', '', false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        MovePurchRegimeCodesToPostedDoc(PurchHeader, SIIPurchDocSchemeCode."Document Type"::"Posted Invoice", PurchInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, 'OnAfterPurchCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterPurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        MovePurchRegimeCodesToPostedDoc(PurchHeader, SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo", PurchCrMemoHdr."No.");
    end;
}

