codeunit 229 "Document-Print"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label '%1 is missing for %2 %3.';
        Text002: Label '%1 for %2 is missing in %3.';
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";

    procedure EmailSalesHeader(SalesHeader: Record "Sales Header")
    begin
        DoPrintSalesHeader(SalesHeader, true);
    end;

    procedure PrintSalesHeader(SalesHeader: Record "Sales Header")
    begin
        DoPrintSalesHeader(SalesHeader, false);
    end;

    local procedure DoPrintSalesHeader(SalesHeader: Record "Sales Header"; SendAsEmail: Boolean)
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        CalcSalesDisc(SalesHeader);
        OnBeforeDoPrintSalesHeader(SalesHeader, GetSalesDocTypeUsage(SalesHeader), SendAsEmail, IsPrinted);
        if IsPrinted then
            exit;

        if SendAsEmail then
            ReportSelections.SendEmailToCust(
              GetSalesDocTypeUsage(SalesHeader), SalesHeader, SalesHeader."No.", SalesHeader.GetDocTypeTxt, true, SalesHeader.GetBillToNo)
        else
            ReportSelections.Print(GetSalesDocTypeUsage(SalesHeader), SalesHeader, SalesHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintPurchHeader(PurchHeader: Record "Purchase Header")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type");
        PurchHeader.SetRange("No.", PurchHeader."No.");
        CalcPurchDisc(PurchHeader);
        OnBeforeDoPrintPurchHeader(PurchHeader, GetPurchDocTypeUsage(PurchHeader), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.PrintWithGUIYesNoVendor(
          GetPurchDocTypeUsage(PurchHeader), PurchHeader, true, PurchHeader.FieldNo("Buy-from Vendor No."));
    end;

    procedure PrintBankAccStmt(BankAccStmt: Record "Bank Account Statement")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        BankAccStmt.SetRecFilter;
        OnBeforePrintBankAccStmt(BankAccStmt, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.Print(ReportSelections.Usage::"B.Stmt", BankAccStmt, 0);
    end;

    procedure PrintCheck(var NewGenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        GenJnlLine.Copy(NewGenJnlLine);
        GenJnlLine.OnCheckGenJournalLinePrintCheckRestrictions;
        OnBeforePrintCheck(GenJnlLine, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.Print(ReportSelections.Usage::"B.Check", GenJnlLine, 0);
    end;

    procedure PrintTransferHeader(TransHeader: Record "Transfer Header")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        TransHeader.SetRange("No.", TransHeader."No.");
        OnBeforePrintTransferHeader(TransHeader, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.Print(ReportSelections.Usage::Inv1, TransHeader, 0);
    end;

    procedure PrintServiceContract(ServiceContract: Record "Service Contract Header")
    var
        ReportSelection: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        ServiceContract.SetRange("Contract No.", ServiceContract."Contract No.");
        OnBeforePrintServiceContract(ServiceContract, GetServContractTypeUsage(ServiceContract), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.FilterPrintUsage(GetServContractTypeUsage(ServiceContract));
        if ReportSelection.IsEmpty then
            Error(Text001, ReportSelection.TableCaption, Format(ServiceContract."Contract Type"), ServiceContract."Contract No.");

        ReportSelection.Print(
          GetServContractTypeUsage(ServiceContract), ServiceContract, ServiceContract.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintServiceHeader(ServiceHeader: Record "Service Header")
    var
        ReportSelection: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        CalcServDisc(ServiceHeader);
        OnBeforePrintServiceHeader(ServiceHeader, GetServHeaderDocTypeUsage(ServiceHeader), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.FilterPrintUsage(GetServHeaderDocTypeUsage(ServiceHeader));
        if ReportSelection.IsEmpty then
            Error(Text002, ReportSelection.FieldCaption("Report ID"), ServiceHeader.TableCaption, ReportSelection.TableCaption);

        ReportSelection.Print(GetServHeaderDocTypeUsage(ServiceHeader), ServiceHeader, ServiceHeader.FieldNo("Customer No."));
    end;

    procedure PrintAsmHeader(AsmHeader: Record "Assembly Header")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        AsmHeader.SetRange("Document Type", AsmHeader."Document Type");
        AsmHeader.SetRange("No.", AsmHeader."No.");
        OnBeforePrintAsmHeader(AsmHeader, GetAsmHeaderDocTypeUsage(AsmHeader), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.Print(GetAsmHeaderDocTypeUsage(AsmHeader), AsmHeader, 0);
    end;

    procedure PrintSalesOrder(SalesHeader: Record "Sales Header"; Usage: Option "Order Confirmation","Work Order","Pick Instruction")
    var
        ReportSelection: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;

        SalesHeader.SetRange("No.", SalesHeader."No.");
        CalcSalesDisc(SalesHeader);
        OnBeforePrintSalesOrder(SalesHeader, GetSalesOrderUsage(Usage), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.PrintWithGUIYesNo(GetSalesOrderUsage(Usage), SalesHeader, GuiAllowed, SalesHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintSalesHeaderArch(SalesHeaderArch: Record "Sales Header Archive")
    var
        ReportSelection: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        SalesHeaderArch.SetRecFilter;
        OnBeforePrintSalesHeaderArch(SalesHeaderArch, GetSalesArchDocTypeUsage(SalesHeaderArch), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.Print(GetSalesArchDocTypeUsage(SalesHeaderArch), SalesHeaderArch, SalesHeaderArch.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintPurchHeaderArch(PurchHeaderArch: Record "Purchase Header Archive")
    var
        ReportSelection: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        PurchHeaderArch.SetRecFilter;
        OnBeforePrintPurchHeaderArch(PurchHeaderArch, GetPurchArchDocTypeUsage(PurchHeaderArch), IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.PrintWithGUIYesNoVendor(
          GetPurchArchDocTypeUsage(PurchHeaderArch), PurchHeaderArch, true, PurchHeaderArch.FieldNo("Buy-from Vendor No."));
    end;

    procedure PrintProformaSalesInvoice(SalesHeader: Record "Sales Header")
    var
        ReportSelections: Record "Report Selections";
        IsPrinted: Boolean;
    begin
        SalesHeader.SetRecFilter;
        OnBeforePrintProformaSalesInvoice(SalesHeader, ReportSelections.Usage::"Pro Forma S. Invoice", IsPrinted);
        if IsPrinted then
            exit;

        ReportSelections.Print(ReportSelections.Usage::"Pro Forma S. Invoice", SalesHeader, SalesHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure PrintInvtOrderTest(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Phys.Invt.Order Test");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PhysInvtOrderHeader);
            until ReportSelections.Next = 0;
    end;

    procedure PrintInvtOrder(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Phys.Invt.Order");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PhysInvtOrderHeader);
            until ReportSelections.Next = 0;
    end;

    procedure PrintPostedInvtOrder(PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PstdPhysInvtOrderHdr.SetRange("No.", PstdPhysInvtOrderHdr."No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Phys.Invt.Order");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PstdPhysInvtOrderHdr);
            until ReportSelections.Next = 0;
    end;

    procedure PrintInvtRecording(PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PhysInvtRecordHeader.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordHeader.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"Phys.Invt.Rec.");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PhysInvtRecordHeader);
            until ReportSelections.Next = 0;
    end;

    procedure PrintPostedInvtRecording(PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr"; ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        PstdPhysInvtRecordHdr.SetRange("Order No.", PstdPhysInvtRecordHdr."Order No.");
        PstdPhysInvtRecordHdr.SetRange("Recording No.", PstdPhysInvtRecordHdr."Recording No.");
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Phys.Invt.Rec.");
        ReportSelections.SetFilter("Report ID", '<>0');
        if ReportSelections.FindSet then
            repeat
                REPORT.RunModal(ReportSelections."Report ID", ShowRequestForm, false, PstdPhysInvtRecordHdr);
            until ReportSelections.Next = 0;
    end;

    local procedure GetSalesDocTypeUsage(SalesHeader: Record "Sales Header"): Integer
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                exit(ReportSelections.Usage::"S.Quote");
            SalesHeader."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"S.Blanket");
            SalesHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"S.Order");
            SalesHeader."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"S.Return");
            SalesHeader."Document Type"::Invoice:
                exit(ReportSelections.Usage::"S.Invoice Draft");
            SalesHeader."Document Type"::"Credit Memo":
                exit(ReportSelections.Usage::"S.Invoice Draft");
            else begin
                    IsHandled := false;
                    OnGetSalesDocTypeUsageElseCase(SalesHeader, TypeUsage, IsHandled);
                    if IsHandled then
                        exit(TypeUsage);
                    Error('');
                end;
        end;
    end;

    local procedure GetPurchDocTypeUsage(PurchHeader: Record "Purchase Header"): Integer
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::Quote:
                exit(ReportSelections.Usage::"P.Quote");
            PurchHeader."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"P.Blanket");
            PurchHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"P.Order");
            PurchHeader."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"P.Return");
            else begin
                    IsHandled := false;
                    OnGetPurchDocTypeUsageElseCase(PurchHeader, TypeUsage, IsHandled);
                    if IsHandled then
                        exit(TypeUsage);
                    Error('');
                end;
        end;
    end;

    local procedure GetServContractTypeUsage(ServiceContractHeader: Record "Service Contract Header"): Integer
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case ServiceContractHeader."Contract Type" of
            ServiceContractHeader."Contract Type"::Quote:
                exit(ReportSelections.Usage::"SM.Contract Quote");
            ServiceContractHeader."Contract Type"::Contract:
                exit(ReportSelections.Usage::"SM.Contract");
            else begin
                    IsHandled := false;
                    OnGetServContractTypeUsageElseCase(ServiceContractHeader, TypeUsage, IsHandled);
                    if IsHandled then
                        exit(TypeUsage);
                    Error('');
                end;
        end;
    end;

    local procedure GetServHeaderDocTypeUsage(ServiceHeader: Record "Service Header"): Integer
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Quote:
                exit(ReportSelections.Usage::"SM.Quote");
            ServiceHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"SM.Order");
            ServiceHeader."Document Type"::Invoice:
                exit(ReportSelections.Usage::"SM.Invoice");
            ServiceHeader."Document Type"::"Credit Memo":
                exit(ReportSelections.Usage::"SM.Credit Memo");
            else begin
                    IsHandled := false;
                    OnGetServHeaderDocTypeUsageElseCase(ServiceHeader, TypeUsage, IsHandled);
                    if IsHandled then
                        exit(TypeUsage);
                    Error('');
                end;
        end;
    end;

    local procedure GetAsmHeaderDocTypeUsage(AsmHeader: Record "Assembly Header"): Integer
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case AsmHeader."Document Type" of
            AsmHeader."Document Type"::Quote,
          AsmHeader."Document Type"::"Blanket Order",
          AsmHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"Asm.Order");
            else begin
                    IsHandled := false;
                    OnGetAsmHeaderTypeUsageElseCase(AsmHeader, TypeUsage, IsHandled);
                    if IsHandled then
                        exit(TypeUsage);
                    Error('');
                end;
        end;
    end;

    local procedure GetSalesOrderUsage(Usage: Option "Order Confirmation","Work Order","Pick Instruction"): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        case Usage of
            Usage::"Order Confirmation":
                exit(ReportSelections.Usage::"S.Order");
            Usage::"Work Order":
                exit(ReportSelections.Usage::"S.Work Order");
            Usage::"Pick Instruction":
                exit(ReportSelections.Usage::"S.Order Pick Instruction");
            else
                Error('');
        end;
    end;

    local procedure GetSalesArchDocTypeUsage(SalesHeaderArchive: Record "Sales Header Archive"): Integer
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case SalesHeaderArchive."Document Type" of
            SalesHeaderArchive."Document Type"::Quote:
                exit(ReportSelections.Usage::"S.Arch.Quote");
            SalesHeaderArchive."Document Type"::Order:
                exit(ReportSelections.Usage::"S.Arch.Order");
            SalesHeaderArchive."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"S.Arch.Return");
            SalesHeaderArchive."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"S.Arch.Blanket");
            else begin
                    IsHandled := false;
                    OnGetSalesArchDocTypeUsageElseCase(SalesHeaderArchive, TypeUsage, IsHandled);
                    if IsHandled then
                        exit(TypeUsage);
                    Error('');
                end;
        end
    end;

    local procedure GetPurchArchDocTypeUsage(PurchHeaderArchive: Record "Purchase Header Archive"): Integer
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case PurchHeaderArchive."Document Type" of
            PurchHeaderArchive."Document Type"::Quote:
                exit(ReportSelections.Usage::"P.Arch.Quote");
            PurchHeaderArchive."Document Type"::Order:
                exit(ReportSelections.Usage::"P.Arch.Order");
            PurchHeaderArchive."Document Type"::"Return Order":
                exit(ReportSelections.Usage::"P.Arch.Return");
            PurchHeaderArchive."Document Type"::"Blanket Order":
                exit(ReportSelections.Usage::"P.Arch.Blanket");
            else begin
                    IsHandled := false;
                    OnGetPurchArchDocTypeUsageElseCase(PurchHeaderArchive, TypeUsage, IsHandled);
                    if IsHandled then
                        exit(TypeUsage);
                    Error('');
                end;
        end;
    end;

    local procedure CalcSalesDisc(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcSalesDisc(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get;
        if SalesSetup."Calc. Inv. Discount" then begin
            SalesLine.Reset;
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.FindFirst;
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
            Commit;
        end;
    end;

    local procedure CalcPurchDisc(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPurchDisc(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get;
        if PurchSetup."Calc. Inv. Discount" then begin
            PurchLine.Reset;
            PurchLine.SetRange("Document Type", PurchHeader."Document Type");
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            PurchLine.FindFirst;
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
            PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
            Commit;
        end;
    end;

    local procedure CalcServDisc(var ServHeader: Record "Service Header")
    var
        ServLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcServDisc(ServHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get;
        if SalesSetup."Calc. Inv. Discount" then begin
            ServLine.Reset;
            ServLine.SetRange("Document Type", ServHeader."Document Type");
            ServLine.SetRange("Document No.", ServHeader."No.");
            ServLine.FindFirst;
            CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServLine);
            ServHeader.Get(ServHeader."Document Type", ServHeader."No.");
            Commit;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSalesDisc(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServDisc(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPurchDisc(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintSalesHeader(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; SendAsEmail: Boolean; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintPurchHeader(var PurchHeader: Record "Purchase Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintBankAccStmt(var BankAccountStatement: Record "Bank Account Statement"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCheck(var GenJournalLine: Record "Gen. Journal Line"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintTransferHeader(var TransferHeader: Record "Transfer Header"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintServiceContract(var ServiceContractHeader: Record "Service Contract Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintServiceHeader(var ServiceHeader: Record "Service Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintAsmHeader(var AssemblyHeader: Record "Assembly Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintSalesOrder(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintSalesHeaderArch(var SalesHeaderArchive: Record "Sales Header Archive"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPurchHeaderArch(var PurchaseHeaderArchive: Record "Purchase Header Archive"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintProformaSalesInvoice(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAsmHeaderTypeUsageElseCase(AssemblyHeader: Record "Assembly Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchDocTypeUsageElseCase(PurchaseHeader: Record "Purchase Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesDocTypeUsageElseCase(SalesHeader: Record "Sales Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetServHeaderDocTypeUsageElseCase(ServiceHeader: Record "Service Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetServContractTypeUsageElseCase(ServiceContractHeader: Record "Service Contract Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesArchDocTypeUsageElseCase(SalesHeaderArchive: Record "Sales Header Archive"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchArchDocTypeUsageElseCase(PurchaseHeaderArchive: Record "Purchase Header Archive"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;
}

