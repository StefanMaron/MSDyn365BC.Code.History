#if not CLEANSCHEMA26 
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;

table 49 "Invoice Post. Buffer"
{
    Caption = 'Invoice Post. Buffer';
    ReplicateData = false;
#pragma warning disable AS0074
    TableType = Temporary;
    ObsoleteReason = 'This table will be replaced by table Invoice Posting Buffer in new Invoice Posting implementation.';
#if CLEAN24
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
#endif
#pragma warning restore AS0074
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Invoice Posting Line Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(2; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(4; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(5; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(6; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        field(7; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            DataClassification = SystemMetadata;
        }
        field(10; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        field(11; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        field(12; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            DataClassification = SystemMetadata;
        }
        field(14; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            DataClassification = SystemMetadata;
        }
        field(17; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = SystemMetadata;
        }
        field(18; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        field(19; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        field(20; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 5;
        }
        field(22; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        field(23; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(24; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(25; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(26; "VAT Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(29; "VAT Base Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(31; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            DataClassification = SystemMetadata;
        }
        field(32; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 1;
        }
        field(35; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Before Pmt. Disc.';
            DataClassification = SystemMetadata;
        }
        field(215; "Entry Description"; Text[100])
        {
            Caption = 'Entry Description';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(1000; "Additional Grouping Identifier"; Code[20])
        {
            Caption = 'Additional Grouping Identifier';
            DataClassification = SystemMetadata;
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = SystemMetadata;
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
            DataClassification = SystemMetadata;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5601; "FA Posting Type"; Enum "Purchase FA Posting Type")
        {
            Caption = 'FA Posting Type';
            DataClassification = SystemMetadata;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            DataClassification = SystemMetadata;
            TableRelation = "Depreciation Book";
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Salvage Value';
            DataClassification = SystemMetadata;
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
            DataClassification = SystemMetadata;
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            DataClassification = SystemMetadata;
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            DataClassification = SystemMetadata;
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            DataClassification = SystemMetadata;
            TableRelation = "Fixed Asset";
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            DataClassification = SystemMetadata;
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
            DataClassification = SystemMetadata;
        }
        field(5614; "Fixed Asset Line No."; Integer)
        {
            Caption = 'Fixed Asset Line No.';
            DataClassification = SystemMetadata;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            DataClassification = SystemMetadata;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base';
            DataClassification = SystemMetadata;
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount';
            DataClassification = SystemMetadata;
        }
        field(6203; "Non-Deductible VAT Base ACY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base ACY';
            DataClassification = SystemMetadata;
        }
        field(6204; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount ACY';
            DataClassification = SystemMetadata;
        }
        field(6205; "Non-Deductible VAT Diff."; Decimal)
        {
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Type, "G/L Account", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Area Code", "Tax Group Code", "Tax Liable", "Use Tax", "Dimension Set ID", "Job No.", "Fixed Asset Line No.", "Deferral Code", "Additional Grouping Identifier")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN24
    var
        InvoicePostBufferErrorTxt: Label 'This procedure is no longer invoked. Replaced by procedure in table Invoice Posting Buffer', Locked = true;
        PurchPostInvoiceErrorTxt: Label 'This procedure is no longer invoked. Replaced by procedure in codeunit Purch. Post Invoice', Locked = true;
        SalesPostInvoiceErrorTxt: Label 'This procedure is no longer invoked. Replaced by procedure in codeunit Sales Post Invoice', Locked = true;
        ServicePostInvoiceErrorTxt: Label 'This procedure is no longer invoked. Replaced by procedure in codeunit Service Post Invoice', Locked = true;

#pragma warning disable AS0072
    [Obsolete('Replaced by procedure in codeunit Sales Post Invoice', '20.0')]
    procedure PrepareSales(var SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        error(SalesPostInvoiceErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CalcDiscount(PricesInclVAT: Boolean; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetAccount(AccountNo: Code[20]; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetAmounts(TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal; TotalVATBase: Decimal; TotalVATBaseACY: Decimal)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure PreparePurchase(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        error(PurchPostInvoiceErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CalcDiscountNoVAT(DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in codeunit Purch Post Invoice', '20.0')]
    procedure SetSalesTaxForPurchLine(PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        error(PurchPostInvoiceErrorTxt);
    end;

    [Obsolete('Replaced by procedure in codeunity Sales Post Invoice', '20.0')]
    procedure SetSalesTaxForSalesLine(SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        error(SalesPostInvoiceErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure ReverseAmounts()
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetAmountsNoVAT(TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in codeunit Service Post Invoice', '20.0')]
    procedure PrepareService(var ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        error(ServicePostInvoiceErrorTxt);
    end;
#endif

#if not CLEAN24
    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure PreparePrepmtAdjBuffer(InvoicePostBuffer: Record "Invoice Post. Buffer"; GLAccountNo: Code[20]; AdjAmount: Decimal; RoundingEntry: Boolean)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure Update(InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure Update(InvoicePostBuffer: Record "Invoice Post. Buffer"; var InvDefLineNo: Integer; var DeferralLineNo: Integer)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure UpdateVATBase(var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CopyToGenJnlLine(var GenJnlLine: Record Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Line")
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CopyToGenJnlLineFA(var GenJnlLine: Record Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Line")
    begin
        error(InvoicePostBufferErrorTxt);
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferPrepareSales(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferPreparePurchase(var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferPrepareService(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferModify(var InvoicePostBuffer: Record "Invoice Post. Buffer"; FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferUpdate(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmountsNoVAT(var InvoicePostBuffer: Record "Invoice Post. Buffer"; TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal)
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDiscount(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDiscountNoVAT(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvPostBufferUpdate(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvPostBufferModify(var InvoicePostBuffer: Record "Invoice Post. Buffer"; FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareSales(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillPrepmtAdjBufferOnBeforeAssignInvoicePostBuffer(var PrepmtAdjInvPostBuffer: Record "Invoice Post. Buffer"; InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLine(var GenJnlLine: Record Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Line"; InvoicePostBuffer: Record "Invoice Post. Buffer");
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLineFA(var GenJnlLine: Record Microsoft.Finance.GeneralLedger.Journal."Gen. Journal Line"; InvoicePostBuffer: Record "Invoice Post. Buffer");
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustRoundingForUpdate(var InvoicePostBuffer: Record "Invoice Post. Buffer"; TempInvoicePostBufferRounding: Record "Invoice Post. Buffer" temporary)
    begin
    end;

    [Obsolete('This procedure is no longer invoked. Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyRoundingForFinalPosting(var InvoicePostBuffer: Record "Invoice Post. Buffer"; TempInvoicePostBufferRounding: Record "Invoice Post. Buffer" temporary)
    begin
    end;
#endif
#pragma warning restore AS0072
}
#endif