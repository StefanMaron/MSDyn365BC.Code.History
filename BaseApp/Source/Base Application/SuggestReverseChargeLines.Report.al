report 31084 "Suggest Reverse Charge Lines"
{
    Caption = 'Suggest Reverse Charge Lines';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this report should not be used. (Obsolete::Removed in release 01.2021)';

    dataset
    {
        dataitem("Reverse Charge Header"; "Reverse Charge Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            dataitem("VAT Posting Setup"; "VAT Posting Setup")
            {
                DataItemTableView = SORTING("VAT Bus. Posting Group", "VAT Prod. Posting Group") WHERE("Reverse Charge Check" = CONST("Limit Check & Export"));
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";

                trigger OnAfterGetRecord()
                begin
                    Suggest("Reverse Charge Header", "VAT Posting Setup");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        LastLineNo: Integer;

    [Scope('OnPrem')]
    procedure Suggest(ReverseChargeHdr: Record "Reverse Charge Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        ReverseChargeLn: Record "Reverse Charge Line";
        StartDate: Date;
        EndDate: Date;
    begin
        GLSetup.Get;

        ReverseChargeLn.SetRange("Reverse Charge No.", ReverseChargeHdr."No.");
        if ReverseChargeLn.FindLast then
            LastLineNo := ReverseChargeLn."Line No."
        else
            LastLineNo := 0;

        StartDate := ReverseChargeHdr."Start Date";
        EndDate := ReverseChargeHdr."End Date";
        if ReverseChargeHdr."Part Period From" <> 0D then
            StartDate := ReverseChargeHdr."Part Period From";
        if ReverseChargeHdr."Part Period To" <> 0D then
            StartDate := ReverseChargeHdr."Part Period To";

        case ReverseChargeHdr."Statement Type" of
            ReverseChargeHdr."Statement Type"::Vendor:
                begin
                    SuggestFromSalesInvLine(ReverseChargeHdr, VATPostingSetup, StartDate, EndDate);
                    SuggestFromSalesCrMemoLine(ReverseChargeHdr, VATPostingSetup, StartDate, EndDate);
                    SuggestFromServInvLine(ReverseChargeHdr, VATPostingSetup, StartDate, EndDate);
                    SuggestFromServCrMemoLine(ReverseChargeHdr, VATPostingSetup, StartDate, EndDate);
                end;
            ReverseChargeHdr."Statement Type"::Customer:
                begin
                    SuggestFromPurchInvLine(ReverseChargeHdr, VATPostingSetup, StartDate, EndDate);
                    SuggestFromPurchCrMemoLine(ReverseChargeHdr, VATPostingSetup, StartDate, EndDate);
                end;
        end;
    end;

    local procedure SuggestFromSalesInvLine(ReverseChargeHdr: Record "Reverse Charge Header"; VATPostingSetup: Record "VAT Posting Setup"; StartDate: Date; EndDate: Date)
    var
        SalesInvHdr: Record "Sales Invoice Header";
        SalesInvLn: Record "Sales Invoice Line";
        TariffNumber: Record "Tariff Number";
        VATDate: Date;
    begin
        with SalesInvLn do begin
            if not GLSetup."Use VAT Date" then
                SetRange("Posting Date", StartDate, EndDate);

            SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            SetFilter("Tariff No.", '<>%1', '');
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then
                repeat
                    if "Document No." <> SalesInvHdr."No." then
                        SalesInvHdr.Get("Document No.");

                    if GLSetup."Use VAT Date" then
                        VATDate := SalesInvHdr."VAT Date"
                    else
                        VATDate := "Posting Date";

                    if (VATDate >= StartDate) and (VATDate <= EndDate) then begin
                        TariffNumber.Get("Tariff No.");

                        CreateReverseChargeLine(
                          ReverseChargeHdr,
                          1,
                          "Document No.",
                          "Line No.",
                          SalesInvHdr."VAT Country/Region Code",
                          SalesInvHdr."VAT Registration No.",
                          Type,
                          "No.",
                          Description,
                          TariffNumber."Statement Code",
                          CalcQty(
                            Type,
                            "No.",
                            Quantity,
                            "Quantity (Base)",
                            "Unit of Measure Code",
                            TariffNumber."VAT Stat. Unit of Measure Code"),
                          TariffNumber."VAT Stat. Unit of Measure Code",
                          CalcVATBaseAmountLCY(
                            "VAT Bus. Posting Group",
                            "VAT Prod. Posting Group",
                            "VAT Base Amount",
                            SalesInvHdr."Currency Code",
                            SalesInvHdr."Currency Factor",
                            SalesInvHdr."Posting Date"),
                          VATDate,
                          Quantity,
                          "Unit of Measure Code",
                          "Tariff No.");
                    end;
                until Next = 0;
        end;
    end;

    local procedure SuggestFromSalesCrMemoLine(ReverseChargeHdr: Record "Reverse Charge Header"; VATPostingSetup: Record "VAT Posting Setup"; StartDate: Date; EndDate: Date)
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLn: Record "Sales Cr.Memo Line";
        TariffNumber: Record "Tariff Number";
        VATDate: Date;
    begin
        with SalesCrMemoLn do begin
            if not GLSetup."Use VAT Date" then
                SetRange("Posting Date", StartDate, EndDate);

            SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            SetFilter("Tariff No.", '<>%1', '');
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then
                repeat
                    if "Document No." <> SalesCrMemoHdr."No." then
                        SalesCrMemoHdr.Get("Document No.");

                    if GLSetup."Use VAT Date" then
                        VATDate := SalesCrMemoHdr."VAT Date"
                    else
                        VATDate := "Posting Date";

                    if (VATDate >= StartDate) and (VATDate <= EndDate) then
                        if not SalesCrMemoHdr."Postponed VAT" then begin
                            TariffNumber.Get("Tariff No.");

                            CreateReverseChargeLine(
                              ReverseChargeHdr,
                              2,
                              "Document No.",
                              "Line No.",
                              SalesCrMemoHdr."VAT Country/Region Code",
                              SalesCrMemoHdr."VAT Registration No.",
                              Type,
                              "No.",
                              Description,
                              TariffNumber."Statement Code",
                              -CalcQty(
                                Type,
                                "No.",
                                Quantity,
                                "Quantity (Base)",
                                "Unit of Measure Code",
                                TariffNumber."VAT Stat. Unit of Measure Code"),
                              TariffNumber."VAT Stat. Unit of Measure Code",
                              -CalcVATBaseAmountLCY(
                                "VAT Bus. Posting Group",
                                "VAT Prod. Posting Group",
                                "VAT Base Amount",
                                SalesCrMemoHdr."Currency Code",
                                SalesCrMemoHdr."Currency Factor",
                                SalesCrMemoHdr."Posting Date"),
                              VATDate,
                              -Quantity,
                              "Unit of Measure Code",
                              "Tariff No.");
                        end;
                until Next = 0;
        end;
    end;

    local procedure SuggestFromPurchInvLine(ReverseChargeHdr: Record "Reverse Charge Header"; VATPostingSetup: Record "VAT Posting Setup"; StartDate: Date; EndDate: Date)
    var
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchInvLn: Record "Purch. Inv. Line";
        TariffNumber: Record "Tariff Number";
        VATDate: Date;
    begin
        with PurchInvLn do begin
            if not GLSetup."Use VAT Date" then
                SetRange("Posting Date", StartDate, EndDate);

            SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            SetFilter("Tariff No.", '<>%1', '');
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then
                repeat
                    if "Document No." <> PurchInvHdr."No." then
                        PurchInvHdr.Get("Document No.");

                    if GLSetup."Use VAT Date" then
                        VATDate := PurchInvHdr."VAT Date"
                    else
                        VATDate := "Posting Date";

                    if (VATDate >= StartDate) and (VATDate <= EndDate) then begin
                        TariffNumber.Get("Tariff No.");

                        CreateReverseChargeLine(
                          ReverseChargeHdr,
                          1,
                          "Document No.",
                          "Line No.",
                          PurchInvHdr."VAT Country/Region Code",
                          PurchInvHdr."VAT Registration No.",
                          Type,
                          "No.",
                          Description,
                          TariffNumber."Statement Code",
                          CalcQty(
                            Type,
                            "No.",
                            Quantity,
                            "Quantity (Base)",
                            "Unit of Measure Code",
                            TariffNumber."VAT Stat. Unit of Measure Code"),
                          TariffNumber."VAT Stat. Unit of Measure Code",
                          CalcVATBaseAmountLCY(
                            "VAT Bus. Posting Group",
                            "VAT Prod. Posting Group",
                            "VAT Base Amount",
                            PurchInvHdr."Currency Code",
                            PurchInvHdr."Currency Factor",
                            PurchInvHdr."Posting Date"),
                          VATDate,
                          Quantity,
                          "Unit of Measure Code",
                          "Tariff No.");
                    end;
                until Next = 0;
        end;
    end;

    local procedure SuggestFromPurchCrMemoLine(ReverseChargeHdr: Record "Reverse Charge Header"; VATPostingSetup: Record "VAT Posting Setup"; StartDate: Date; EndDate: Date)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLn: Record "Purch. Cr. Memo Line";
        TariffNumber: Record "Tariff Number";
        VATDate: Date;
    begin
        with PurchCrMemoLn do begin
            if not GLSetup."Use VAT Date" then
                SetRange("Posting Date", StartDate, EndDate);

            SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            SetFilter("Tariff No.", '<>%1', '');
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then
                repeat
                    if "Document No." <> PurchCrMemoHdr."No." then
                        PurchCrMemoHdr.Get("Document No.");

                    if GLSetup."Use VAT Date" then
                        VATDate := PurchCrMemoHdr."VAT Date"
                    else
                        VATDate := "Posting Date";

                    if (VATDate >= StartDate) and (VATDate <= EndDate) then begin
                        TariffNumber.Get("Tariff No.");

                        CreateReverseChargeLine(
                          ReverseChargeHdr,
                          2,
                          "Document No.",
                          "Line No.",
                          PurchCrMemoHdr."VAT Country/Region Code",
                          PurchCrMemoHdr."VAT Registration No.",
                          Type,
                          "No.",
                          Description,
                          TariffNumber."Statement Code",
                          -CalcQty(
                            Type,
                            "No.",
                            Quantity,
                            "Quantity (Base)",
                            "Unit of Measure Code",
                            TariffNumber."VAT Stat. Unit of Measure Code"),
                          TariffNumber."VAT Stat. Unit of Measure Code",
                          -CalcVATBaseAmountLCY(
                            "VAT Bus. Posting Group",
                            "VAT Prod. Posting Group",
                            "VAT Base Amount",
                            PurchCrMemoHdr."Currency Code",
                            PurchCrMemoHdr."Currency Factor",
                            PurchCrMemoHdr."Posting Date"),
                          VATDate,
                          -Quantity,
                          "Unit of Measure Code",
                          "Tariff No.");
                    end;
                until Next = 0;
        end;
    end;

    local procedure SuggestFromServInvLine(ReverseChargeHdr: Record "Reverse Charge Header"; VATPostingSetup: Record "VAT Posting Setup"; StartDate: Date; EndDate: Date)
    var
        ServInvHdr: Record "Service Invoice Header";
        ServInvLn: Record "Service Invoice Line";
        TariffNumber: Record "Tariff Number";
        VATDate: Date;
    begin
        with ServInvLn do begin
            if not GLSetup."Use VAT Date" then
                SetRange("Posting Date", StartDate, EndDate);

            SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            SetFilter("Tariff No.", '<>%1', '');
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then
                repeat
                    if "Document No." <> ServInvHdr."No." then
                        ServInvHdr.Get("Document No.");

                    if GLSetup."Use VAT Date" then
                        VATDate := ServInvHdr."VAT Date"
                    else
                        VATDate := "Posting Date";

                    if (VATDate >= StartDate) and (VATDate <= EndDate) then begin
                        TariffNumber.Get("Tariff No.");

                        CreateReverseChargeLine(
                          ReverseChargeHdr,
                          1,
                          "Document No.",
                          "Line No.",
                          ServInvHdr."VAT Country/Region Code",
                          ServInvHdr."VAT Registration No.",
                          Type,
                          "No.",
                          Description,
                          TariffNumber."Statement Code",
                          CalcQty(
                            Type,
                            "No.",
                            Quantity,
                            "Quantity (Base)",
                            "Unit of Measure Code",
                            TariffNumber."VAT Stat. Unit of Measure Code"),
                          TariffNumber."VAT Stat. Unit of Measure Code",
                          CalcVATBaseAmountLCY(
                            "VAT Bus. Posting Group",
                            "VAT Prod. Posting Group",
                            "VAT Base Amount",
                            ServInvHdr."Currency Code",
                            ServInvHdr."Currency Factor",
                            ServInvHdr."Posting Date"),
                          VATDate,
                          Quantity,
                          "Unit of Measure Code",
                          "Tariff No.");
                    end;
                until Next = 0;
        end;
    end;

    local procedure SuggestFromServCrMemoLine(ReverseChargeHdr: Record "Reverse Charge Header"; VATPostingSetup: Record "VAT Posting Setup"; StartDate: Date; EndDate: Date)
    var
        ServCrMemoHdr: Record "Service Cr.Memo Header";
        ServCrMemoLn: Record "Service Cr.Memo Line";
        TariffNumber: Record "Tariff Number";
        VATDate: Date;
    begin
        with ServCrMemoLn do begin
            if not GLSetup."Use VAT Date" then
                SetRange("Posting Date", StartDate, EndDate);

            SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            SetFilter("Tariff No.", '<>%1', '');
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then
                repeat
                    if "Document No." <> ServCrMemoHdr."No." then
                        ServCrMemoHdr.Get("Document No.");

                    if GLSetup."Use VAT Date" then
                        VATDate := ServCrMemoHdr."VAT Date"
                    else
                        VATDate := "Posting Date";

                    if (VATDate >= StartDate) and (VATDate <= EndDate) then begin
                        TariffNumber.Get("Tariff No.");

                        CreateReverseChargeLine(
                          ReverseChargeHdr,
                          2,
                          "Document No.",
                          "Line No.",
                          ServCrMemoHdr."VAT Country/Region Code",
                          ServCrMemoHdr."VAT Registration No.",
                          Type,
                          "No.",
                          Description,
                          TariffNumber."Statement Code",
                          -CalcQty(
                            Type,
                            "No.",
                            Quantity,
                            "Quantity (Base)",
                            "Unit of Measure Code",
                            TariffNumber."VAT Stat. Unit of Measure Code"),
                          TariffNumber."VAT Stat. Unit of Measure Code",
                          -CalcVATBaseAmountLCY(
                            "VAT Bus. Posting Group",
                            "VAT Prod. Posting Group",
                            "VAT Base Amount",
                            ServCrMemoHdr."Currency Code",
                            ServCrMemoHdr."Currency Factor",
                            ServCrMemoHdr."Posting Date"),
                          VATDate,
                          -Quantity,
                          "Unit of Measure Code",
                          "Tariff No.");
                    end;
                until Next = 0;
        end;
    end;

    local procedure CreateReverseChargeLine(ReverseChargeHdr: Record "Reverse Charge Header"; DocumentType: Option; DocumentNo: Code[20]; DocumentLineNo: Integer; CountryCode: Code[10]; VATRegistrationNo: Text[20]; Type: Option; No: Code[20]; Description: Text[100]; CommodityCode: Code[10]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; VATBaseAmountLCY: Decimal; VATDate: Date; DocumentQty: Decimal; DocumentUnitOfMeasureCode: Code[10]; DocumentTariffNo: Code[20])
    var
        ReverseChargeLn: Record "Reverse Charge Line";
    begin
        LastLineNo += 10000;

        ReverseChargeLn.Init;
        ReverseChargeLn."Reverse Charge No." := ReverseChargeHdr."No.";
        ReverseChargeLn."Line No." := LastLineNo;
        ReverseChargeLn.Insert(true);

        ReverseChargeLn."Document Type" := DocumentType;
        ReverseChargeLn."Document No." := DocumentNo;
        ReverseChargeLn."Document Line No." := DocumentLineNo;
        ReverseChargeLn."Country/Region Code" := CountryCode;
        ReverseChargeLn."VAT Registration No." := VATRegistrationNo;
        ReverseChargeLn.Type := Type;
        ReverseChargeLn."No." := No;
        ReverseChargeLn.Description := Description;
        ReverseChargeLn."Commodity Code" := CommodityCode;
        ReverseChargeLn.Quantity := Quantity;
        ReverseChargeLn."Unit of Measure Code" := UnitOfMeasureCode;
        ReverseChargeLn."VAT Base Amount (LCY)" := VATBaseAmountLCY;
        ReverseChargeLn."VAT Date" := VATDate;
        ReverseChargeLn."Document Quantity" := DocumentQty;
        ReverseChargeLn."Document Unit of Measure Code" := DocumentUnitOfMeasureCode;
        ReverseChargeLn."Document Tariff No." := DocumentTariffNo;
        ReverseChargeLn.Modify;
    end;

    local procedure CalcQty(Type: Option; No: Code[20]; Qty: Decimal; QtyBase: Decimal; UnitOfMeasureCode: Code[10]; VATStatUnitOfMeasureCode: Code[10]): Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
    begin
        if VATStatUnitOfMeasureCode = '' then
            exit(0);

        if (UnitOfMeasureCode = VATStatUnitOfMeasureCode) or
           not (Type in [2, 3])
        then
            exit(Qty);

        case Type of
            2: // Item
                begin
                    ItemUnitOfMeasure.Get(No, VATStatUnitOfMeasureCode);
                    ItemUnitOfMeasure.TestField("Qty. per Unit of Measure");
                    exit(Round(QtyBase / ItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001));
                end;
            3: // Resource
                begin
                    ResourceUnitOfMeasure.Get(No, VATStatUnitOfMeasureCode);
                    ResourceUnitOfMeasure.TestField("Qty. per Unit of Measure");
                    exit(Round(QtyBase / ResourceUnitOfMeasure."Qty. per Unit of Measure", 0.00001));
                end;
        end;
    end;

    local procedure CalcVATBaseAmountLCY(VATBusPostGroup: Code[20]; VATProdPostGroup: Code[20]; VATBaseAmt: Decimal; CurrCode: Code[10]; CurrFactor: Decimal; PostingDate: Date) VATBaseAmtLCY: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        VATBaseAmtLCY := 0;

        if CurrCode = '' then
            VATBaseAmtLCY := VATBaseAmt
        else begin
            GenJnlLine.Init;
            GenJnlLine.Validate("VAT Bus. Posting Group", VATBusPostGroup);
            GenJnlLine.Validate("VAT Prod. Posting Group", VATProdPostGroup);
            GenJnlLine.Validate("Posting Date", PostingDate);
            GenJnlLine.Validate("Currency Code", CurrCode);
            GenJnlLine.Validate("Currency Factor", CurrFactor);
            GenJnlLine.Validate("VAT Base Amount", VATBaseAmt);
            VATBaseAmtLCY := GenJnlLine."VAT Base Amount (LCY)";
        end;
    end;
}

