namespace Microsoft.Finance.ReceivablesPayables;

#if not CLEAN23
using Microsoft.Finance.Currency;
#endif
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
#if not CLEAN23
using Microsoft.Finance.GeneralLedger.Journal;
#endif
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
#if not CLEAN23
using Microsoft.Finance.VAT.Calculation;
#endif
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;
#if not CLEAN23
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
#endif

table 49 "Invoice Post. Buffer"
{
    Caption = 'Invoice Post. Buffer';
    ReplicateData = false;
#pragma warning disable AS0074
    TableType = Temporary;
    ObsoleteReason = 'This table will be replaced by table Invoice Posting Buffer in new Invoice Posting implementation.';
#if CLEAN23
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
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

#if not CLEAN23
    var
        TempInvoicePostBufferRounding: Record "Invoice Post. Buffer" temporary;
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        DimMgt: Codeunit DimensionManagement;

#pragma warning disable AS0072
    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure PrepareSales(var SalesLine: Record "Sales Line")
    begin
        OnBeforePrepareSales(Rec, SalesLine);

        Clear(Rec);
        Type := SalesLine.Type;
        "System-Created Entry" := true;
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := SalesLine."VAT Calculation Type";
        "Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Job No." := SalesLine."Job No.";
        "VAT %" := SalesLine."VAT %";
        "VAT Difference" := SalesLine."VAT Difference";
        if Type = Type::"Fixed Asset" then begin
            "FA Posting Date" := SalesLine."FA Posting Date";
            "Depreciation Book Code" := SalesLine."Depreciation Book Code";
            "Depr. until FA Posting Date" := SalesLine."Depr. until FA Posting Date";
            "Duplicate in Depreciation Book" := SalesLine."Duplicate in Depreciation Book";
            "Use Duplication List" := SalesLine."Use Duplication List";
        end;

        UpdateEntryDescriptionFromSalesLine(SalesLine);

        if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
            SetSalesTaxForSalesLine(SalesLine);

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");

        if SalesLine."Line Discount %" = 100 then begin
            "VAT Base Amount" := 0;
            "VAT Base Amount (ACY)" := 0;
            "VAT Amount" := 0;
            "VAT Amount (ACY)" := 0;
#if not CLEAN23
            NonDeductibleVAT.ClearNonDeductibleVAT(Rec);
#endif
        end;

        OnAfterInvPostBufferPrepareSales(SalesLine, Rec);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CalcDiscount(PricesInclVAT: Boolean; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        CurrencyLCY: Record Currency;
        CurrencyACY: Record Currency;
        GLSetup: Record "General Ledger Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDiscount(Rec, IsHandled);
        if IsHandled then
            exit;

        CurrencyLCY.InitRoundingPrecision();
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then
            CurrencyACY.Get(GLSetup."Additional Reporting Currency")
        else
            CurrencyACY := CurrencyLCY;
        "VAT Amount" := Round(
            CalcVATAmount(PricesInclVAT, DiscountAmount, "VAT %"),
            CurrencyLCY."Amount Rounding Precision",
            CurrencyLCY.VATRoundingDirection());
        "VAT Amount (ACY)" := Round(
            CalcVATAmount(PricesInclVAT, DiscountAmountACY, "VAT %"),
            CurrencyACY."Amount Rounding Precision",
            CurrencyACY.VATRoundingDirection());

        if PricesInclVAT and ("VAT %" <> 0) then begin
            "VAT Base Amount" := DiscountAmount - "VAT Amount";
            "VAT Base Amount (ACY)" := DiscountAmountACY - "VAT Amount (ACY)";
        end else begin
            "VAT Base Amount" := DiscountAmount;
            "VAT Base Amount (ACY)" := DiscountAmountACY;
        end;
        Amount := "VAT Base Amount";
        "Amount (ACY)" := "VAT Base Amount (ACY)";
        "VAT Base Before Pmt. Disc." := "VAT Base Amount";
#if not CLEAN23
        NonDeductibleVAT.Calculate(Rec);
#endif        
    end;

    local procedure CalcVATAmount(ValueInclVAT: Boolean; Value: Decimal; VATPercent: Decimal): Decimal
    begin
        if VATPercent = 0 then
            exit(0);
        if ValueInclVAT then
            exit(Value / (1 + (VATPercent / 100)) * (VATPercent / 100));

        exit(Value * (VATPercent / 100));
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetAccount(AccountNo: Code[20]; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        TotalVAT := TotalVAT - "VAT Amount";
        TotalVATACY := TotalVATACY - "VAT Amount (ACY)";
        TotalAmount := TotalAmount - Amount;
        TotalAmountACY := TotalAmountACY - "Amount (ACY)";
        "G/L Account" := AccountNo;
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetAmounts(TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal; TotalVATBase: Decimal; TotalVATBaseACY: Decimal)
    begin
        Amount := TotalAmount;
        "VAT Base Amount" := TotalVATBase;
        "VAT Amount" := TotalVAT;
        "Amount (ACY)" := TotalAmountACY;
        "VAT Base Amount (ACY)" := TotalVATBaseACY;
        "VAT Amount (ACY)" := TotalVATACY;
        "VAT Difference" := VATDifference;
        "VAT Base Before Pmt. Disc." := TotalAmount;
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure PreparePurchase(var PurchLine: Record "Purchase Line")
    begin
        Clear(Rec);
        Type := PurchLine.Type;
        "System-Created Entry" := true;
        "Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := PurchLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := PurchLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := PurchLine."VAT Calculation Type";
        "Global Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Job No." := PurchLine."Job No.";
        "VAT %" := PurchLine."VAT %";
        "VAT Difference" := PurchLine."VAT Difference";
#if not CLEAN23
        NonDeductibleVAT.Copy(Rec, PurchLine);
#endif        
        if Type = Type::"Fixed Asset" then begin
            "FA Posting Date" := PurchLine."FA Posting Date";
            "Depreciation Book Code" := PurchLine."Depreciation Book Code";
            "Depr. until FA Posting Date" := PurchLine."Depr. until FA Posting Date";
            "Duplicate in Depreciation Book" := PurchLine."Duplicate in Depreciation Book";
            "Use Duplication List" := PurchLine."Use Duplication List";
            "FA Posting Type" := PurchLine."FA Posting Type";
            "Depreciation Book Code" := PurchLine."Depreciation Book Code";
            "Salvage Value" := PurchLine."Salvage Value";
            "Depr. Acquisition Cost" := PurchLine."Depr. Acquisition Cost";
            "Maintenance Code" := PurchLine."Maintenance Code";
            "Insurance No." := PurchLine."Insurance No.";
            "Budgeted FA No." := PurchLine."Budgeted FA No.";
        end;

        UpdateEntryDescriptionFromPurchaseLine(PurchLine);

        if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
            SetSalesTaxForPurchLine(PurchLine);

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");

        if PurchLine."Line Discount %" = 100 then begin
            "VAT Base Amount" := 0;
            "VAT Base Amount (ACY)" := 0;
            "VAT Amount" := 0;
            "VAT Amount (ACY)" := 0;
#if not CLEAN23
            NonDeductibleVAT.ClearNonDeductibleVAT(Rec);
#endif            
        end;

        OnAfterInvPostBufferPreparePurchase(PurchLine, Rec);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CalcDiscountNoVAT(DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        IsHandled: boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDiscountNoVAT(Rec, IsHandled);
        if IsHandled then
            exit;

        "VAT Base Amount" := DiscountAmount;
        "VAT Base Amount (ACY)" := DiscountAmountACY;
        Amount := "VAT Base Amount";
        "Amount (ACY)" := "VAT Base Amount (ACY)";
        "VAT Base Before Pmt. Disc." := "VAT Base Amount";
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetSalesTaxForPurchLine(PurchaseLine: Record "Purchase Line")
    begin
        "Tax Area Code" := PurchaseLine."Tax Area Code";
        "Tax Liable" := PurchaseLine."Tax Liable";
        "Tax Group Code" := PurchaseLine."Tax Group Code";
        "Use Tax" := PurchaseLine."Use Tax";
        Quantity := PurchaseLine."Qty. to Invoice (Base)";
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetSalesTaxForSalesLine(SalesLine: Record "Sales Line")
    begin
        "Tax Area Code" := SalesLine."Tax Area Code";
        "Tax Liable" := SalesLine."Tax Liable";
        "Tax Group Code" := SalesLine."Tax Group Code";
        "Use Tax" := false;
        Quantity := SalesLine."Qty. to Invoice (Base)";
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure ReverseAmounts()
    begin
        Amount := -Amount;
        "VAT Base Amount" := -"VAT Base Amount";
        "Amount (ACY)" := -"Amount (ACY)";
        "VAT Base Amount (ACY)" := -"VAT Base Amount (ACY)";
        "VAT Amount" := -"VAT Amount";
        "VAT Amount (ACY)" := -"VAT Amount (ACY)";
#if not CLEAN23
        NonDeductibleVAT.Reverse(Rec);
#endif        
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure SetAmountsNoVAT(TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal)
    begin
        Amount := TotalAmount;
        "VAT Base Amount" := TotalAmount;
        "VAT Amount" := 0;
        "Amount (ACY)" := TotalAmountACY;
        "VAT Base Amount (ACY)" := TotalAmountACY;
        "VAT Amount (ACY)" := 0;
        "VAT Difference" := VATDifference;
        OnAfterSetAmountsNoVAT(Rec, TotalAmount, TotalAmountACY, VATDifference);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure PrepareService(var ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        Clear(Rec);
        case ServiceLine.Type of
            ServiceLine.Type::Item:
                Type := Type::Item;
            ServiceLine.Type::Resource:
                Type := Type::Resource;
            ServiceLine.Type::"G/L Account":
                Type := Type::"G/L Account";
        end;
        "System-Created Entry" := true;
        "Gen. Bus. Posting Group" := ServiceLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServiceLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := ServiceLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := ServiceLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := ServiceLine."VAT Calculation Type";
        "Global Dimension 1 Code" := ServiceLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := ServiceLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServiceLine."Dimension Set ID";
        "Job No." := ServiceLine."Job No.";
        "VAT %" := ServiceLine."VAT %";
        "VAT Difference" := ServiceLine."VAT Difference";
        if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then begin
            "Tax Area Code" := ServiceLine."Tax Area Code";
            "Tax Group Code" := ServiceLine."Tax Group Code";
            "Tax Liable" := ServiceLine."Tax Liable";
            "Use Tax" := false;
            Quantity := ServiceLine."Qty. to Invoice (Base)";
        end;

        UpdateEntryDescriptionFromServiceLine(ServiceLine);

        OnAfterInvPostBufferPrepareService(ServiceLine, Rec);
    end;
#endif

#if not CLEAN23
    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure PreparePrepmtAdjBuffer(InvoicePostBuffer: Record "Invoice Post. Buffer"; GLAccountNo: Code[20]; AdjAmount: Decimal; RoundingEntry: Boolean)
    var
        PrepmtAdjInvoicePostBuffer: Record "Invoice Post. Buffer";
    begin
        PrepmtAdjInvoicePostBuffer.Init();
        PrepmtAdjInvoicePostBuffer.Type := Type::"Prepmt. Exch. Rate Difference";
        PrepmtAdjInvoicePostBuffer."G/L Account" := GLAccountNo;
        PrepmtAdjInvoicePostBuffer.Amount := AdjAmount;
        if RoundingEntry then
            PrepmtAdjInvoicePostBuffer."Amount (ACY)" := AdjAmount
        else
            PrepmtAdjInvoicePostBuffer."Amount (ACY)" := 0;
        PrepmtAdjInvoicePostBuffer."Dimension Set ID" := InvoicePostBuffer."Dimension Set ID";
        PrepmtAdjInvoicePostBuffer."Global Dimension 1 Code" := InvoicePostBuffer."Global Dimension 1 Code";
        PrepmtAdjInvoicePostBuffer."Global Dimension 2 Code" := InvoicePostBuffer."Global Dimension 2 Code";
        PrepmtAdjInvoicePostBuffer."System-Created Entry" := true;
        PrepmtAdjInvoicePostBuffer."Entry Description" := InvoicePostBuffer."Entry Description";
        OnFillPrepmtAdjBufferOnBeforeAssignInvoicePostBuffer(PrepmtAdjInvoicePostBuffer, InvoicePostBuffer);
        InvoicePostBuffer := PrepmtAdjInvoicePostBuffer;

        Rec := InvoicePostBuffer;
        if Rec.Find() then begin
            Rec.Amount += InvoicePostBuffer.Amount;
            Rec."Amount (ACY)" += InvoicePostBuffer."Amount (ACY)";
            Rec.Modify();
        end else begin
            Rec := InvoicePostBuffer;
            Rec.Insert();
        end;
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure Update(InvoicePostBuffer: Record "Invoice Post. Buffer")
    var
        InvDefLineNo: Integer;
        DeferralLineNo: Integer;
    begin
        Update(InvoicePostBuffer, InvDefLineNo, DeferralLineNo);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure Update(InvoicePostBuffer: Record "Invoice Post. Buffer"; var InvDefLineNo: Integer; var DeferralLineNo: Integer)
    begin
        OnBeforeInvPostBufferUpdate(Rec, InvoicePostBuffer);

        Rec := InvoicePostBuffer;
        if Find() then begin
            Amount += InvoicePostBuffer.Amount;
            "VAT Amount" += InvoicePostBuffer."VAT Amount";
            "VAT Base Amount" += InvoicePostBuffer."VAT Base Amount";
            "Amount (ACY)" += InvoicePostBuffer."Amount (ACY)";
            "VAT Amount (ACY)" += InvoicePostBuffer."VAT Amount (ACY)";
            "VAT Difference" += InvoicePostBuffer."VAT Difference";
            "VAT Base Amount (ACY)" += InvoicePostBuffer."VAT Base Amount (ACY)";
#if not CLEAN23
            NonDeductibleVAT.Increment(Rec, InvoicePostBuffer);
#endif            
            Quantity += InvoicePostBuffer.Quantity;
            "VAT Base Before Pmt. Disc." += InvoicePostBuffer."VAT Base Before Pmt. Disc.";
            if not InvoicePostBuffer."System-Created Entry" then
                "System-Created Entry" := false;
            if "Deferral Code" = '' then
                AdjustRoundingForUpdate();
            OnBeforeInvPostBufferModify(Rec, InvoicePostBuffer);
            Modify();
            OnAfterInvPostBufferModify(Rec, InvoicePostBuffer);
            InvDefLineNo := "Deferral Line No.";
        end else begin
            if "Deferral Code" <> '' then begin
                DeferralLineNo := DeferralLineNo + 1;
                "Deferral Line No." := DeferralLineNo;
                InvDefLineNo := "Deferral Line No.";
            end;
            Insert();
        end;

        OnAfterInvPostBufferUpdate(Rec, InvoicePostBuffer);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure UpdateVATBase(var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVATBase := TotalVATBase - "VAT Base Amount";
        TotalVATBaseACY := TotalVATBaseACY - "VAT Base Amount (ACY)"
    end;

    local procedure UpdateEntryDescriptionFromPurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchSetup: record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchaseHeader.get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdateEntryDescription(
            PurchSetup."Copy Line Descr. to G/L Entry",
            PurchaseLine."Line No.",
            PurchaseLine.Description,
            PurchaseHeader."Posting Description");
    end;

    local procedure UpdateEntryDescriptionFromSalesLine(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesHeader.get(SalesLine."Document Type", SalesLine."Document No.");
        UpdateEntryDescription(
            SalesSetup."Copy Line Descr. to G/L Entry",
            SalesLine."Line No.",
            SalesLine.Description,
            SalesHeader."Posting Description");
    end;

    local procedure UpdateEntryDescriptionFromServiceLine(ServiceLine: Record Microsoft.Service.Document."Service Line")
    var
        ServiceHeader: Record Microsoft.Service.Document."Service Header";
        ServiceSetup: record Microsoft.Service.Setup."Service Mgt. Setup";
    begin
        ServiceSetup.Get();
        ServiceHeader.get(ServiceLine."Document Type", ServiceLine."Document No.");
        UpdateEntryDescription(
            ServiceSetup."Copy Line Descr. to G/L Entry",
            ServiceLine."Line No.",
            ServiceLine.Description,
            ServiceHeader."Posting Description");
    end;

    local procedure UpdateEntryDescription(CopyLineDescrToGLEntry: Boolean; LineNo: Integer; LineDescription: text[100]; HeaderDescription: Text[100])
    begin
        if CopyLineDescrToGLEntry and (Type = type::"G/L Account") then begin
            "Entry Description" := LineDescription;
            "Fixed Asset Line No." := LineNo;
        end else
            "Entry Description" := HeaderDescription;
    end;

    local procedure AdjustRoundingForUpdate()
    begin
        AdjustRoundingFieldsPair(TempInvoicePostBufferRounding.Amount, Amount, "Amount (ACY)");
        AdjustRoundingFieldsPair(TempInvoicePostBufferRounding."VAT Amount", "VAT Amount", "VAT Amount (ACY)");
        AdjustRoundingFieldsPair(TempInvoicePostBufferRounding."VAT Base Amount", "VAT Base Amount", "VAT Base Amount (ACY)");
#if not CLEAN23
        NonDeductibleVAT.AdjustRoundingForInvoicePostBufferUpdate(TempInvoicePostBufferRounding, Rec);
#endif        
        OnAfterAdjustRoundingForUpdate(Rec, TempInvoicePostBufferRounding);
    end;

    local procedure AdjustRoundingFieldsPair(var TotalRoundingAmount: Decimal; var AmountLCY: Decimal; AmountFCY: Decimal)
    begin
        if (AmountLCY <> 0) and (AmountFCY = 0) then begin
            TotalRoundingAmount += AmountLCY;
            AmountLCY := 0;
        end;
    end;

    internal procedure ApplyRoundingForFinalPosting()
    begin
        ApplyRoundingValueForFinalPosting(TempInvoicePostBufferRounding.Amount, Amount);
        ApplyRoundingValueForFinalPosting(TempInvoicePostBufferRounding."VAT Amount", "VAT Amount");
        ApplyRoundingValueForFinalPosting(TempInvoicePostBufferRounding."VAT Base Amount", "VAT Base Amount");
#if not CLEAN23
        NonDeductibleVAT.ApplyRoundingForFinalPostingFromInvoicePostBuffer(TempInvoicePostBufferRounding, Rec);
#endif        
        OnAfterApplyRoundingForFinalPosting(Rec, TempInvoicePostBufferRounding);
    end;

    local procedure ApplyRoundingValueForFinalPosting(var Rounding: Decimal; var Value: Decimal)
    begin
        if (Rounding <> 0) and (Value <> 0) then begin
            Value += Rounding;
            Rounding := 0;
        end;
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Account No." := Rec."G/L Account";
        GenJnlLine."System-Created Entry" := Rec."System-Created Entry";
        GenJnlLine."Gen. Bus. Posting Group" := Rec."Gen. Bus. Posting Group";
        GenJnlLine."Gen. Prod. Posting Group" := Rec."Gen. Prod. Posting Group";
        GenJnlLine."VAT Bus. Posting Group" := Rec."VAT Bus. Posting Group";
        GenJnlLine."VAT Prod. Posting Group" := Rec."VAT Prod. Posting Group";
        GenJnlLine."Tax Area Code" := Rec."Tax Area Code";
        GenJnlLine."Tax Liable" := Rec."Tax Liable";
        GenJnlLine."Tax Group Code" := Rec."Tax Group Code";
        GenJnlLine."Use Tax" := Rec."Use Tax";
        GenJnlLine.Quantity := Rec.Quantity;
        GenJnlLine."VAT %" := Rec."VAT %";
        GenJnlLine."VAT Calculation Type" := Rec."VAT Calculation Type";
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
        GenJnlLine."Job No." := Rec."Job No.";
        GenJnlLine."Deferral Code" := Rec."Deferral Code";
        GenJnlLine."Deferral Line No." := Rec."Deferral Line No.";
        GenJnlLine.Amount := Rec.Amount;
        GenJnlLine."Source Currency Amount" := Rec."Amount (ACY)";
        GenJnlLine."VAT Base Amount" := Rec."VAT Base Amount";
        GenJnlLine."Source Curr. VAT Base Amount" := Rec."VAT Base Amount (ACY)";
        GenJnlLine."VAT Amount" := Rec."VAT Amount";
        GenJnlLine."Source Curr. VAT Amount" := Rec."VAT Amount (ACY)";
        GenJnlLine."VAT Difference" := Rec."VAT Difference";
        GenJnlLine."VAT Base Before Pmt. Disc." := Rec."VAT Base Before Pmt. Disc.";
#if not CLEAN23
        NonDeductibleVAT.Copy(GenJnlLine, Rec);
#endif        

        OnAfterCopyToGenJnlLine(GenJnlLine, Rec);
    end;

    [Obsolete('Replaced by procedure in table Invoice Posting Buffer', '20.0')]
    procedure CopyToGenJnlLineFA(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine."Account Type" := "Gen. Journal Account Type"::"Fixed Asset";
        GenJnlLine."FA Posting Date" := Rec."FA Posting Date";
        GenJnlLine."Depreciation Book Code" := Rec."Depreciation Book Code";
        GenJnlLine."Salvage Value" := Rec."Salvage Value";
        GenJnlLine."Depr. until FA Posting Date" := Rec."Depr. until FA Posting Date";
        GenJnlLine."Depr. Acquisition Cost" := Rec."Depr. Acquisition Cost";
        GenJnlLine."Maintenance Code" := Rec."Maintenance Code";
        GenJnlLine."Insurance No." := Rec."Insurance No.";
        GenJnlLine."Budgeted FA No." := Rec."Budgeted FA No.";
        GenJnlLine."Duplicate in Depreciation Book" := Rec."Duplicate in Depreciation Book";
        GenJnlLine."Use Duplication List" := Rec."Use Duplication List";

        OnAfterCopyToGenJnlLineFA(GenJnlLine, Rec);
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferPrepareSales(var SalesLine: Record "Sales Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferPreparePurchase(var PurchaseLine: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferPrepareService(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferModify(var InvoicePostBuffer: Record "Invoice Post. Buffer"; FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInvPostBufferUpdate(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmountsNoVAT(var InvoicePostBuffer: Record "Invoice Post. Buffer"; TotalAmount: Decimal; TotalAmountACY: Decimal; VATDifference: Decimal)
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDiscount(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDiscountNoVAT(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvPostBufferUpdate(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvPostBufferModify(var InvoicePostBuffer: Record "Invoice Post. Buffer"; FromInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareSales(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var SalesLine: Record "Sales Line")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFillPrepmtAdjBufferOnBeforeAssignInvoicePostBuffer(var PrepmtAdjInvPostBuffer: Record "Invoice Post. Buffer"; InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; InvoicePostBuffer: Record "Invoice Post. Buffer");
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLineFA(var GenJnlLine: Record "Gen. Journal Line"; InvoicePostBuffer: Record "Invoice Post. Buffer");
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustRoundingForUpdate(var InvoicePostBuffer: Record "Invoice Post. Buffer"; TempInvoicePostBufferRounding: Record "Invoice Post. Buffer" temporary)
    begin
    end;

    [Obsolete('Replaced by event in table Invoice Posting Buffer', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyRoundingForFinalPosting(var InvoicePostBuffer: Record "Invoice Post. Buffer"; TempInvoicePostBufferRounding: Record "Invoice Post. Buffer" temporary)
    begin
    end;
#endif
#pragma warning restore AS0072
}
