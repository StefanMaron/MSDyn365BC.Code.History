report 31067 "Suggest VIES Declaration Lines"
{
    Caption = 'Suggest VIES Declaration Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VIES Declaration Header"; "VIES Declaration Header")
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            dataitem(VATEntrySale; "VAT Entry")
            {
                DataItemTableView = SORTING(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Date") WHERE(Type = CONST(Sale));

                trigger OnAfterGetRecord()
                begin
                    UpdateProgressBar;
                    AddVIESLine(VATEntrySale);
                end;

                trigger OnPreDataItem()
                begin
                    if "VIES Declaration Header"."Trade Type" = "VIES Declaration Header"."Trade Type"::Purchases then
                        CurrReport.Break;

                    SetFilters(VATEntrySale);

                    RecordNo := 0;
                    NoOfRecords := Count;
                    OldTime := Time;
                end;
            }
            dataitem(VATEntryPurchase; "VAT Entry")
            {
                DataItemTableView = SORTING(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Date") WHERE(Type = CONST(Purchase));

                trigger OnAfterGetRecord()
                begin
                    UpdateProgressBar;
                    AddVIESLine(VATEntryPurchase);
                end;

                trigger OnPreDataItem()
                begin
                    if "VIES Declaration Header"."Trade Type" = "VIES Declaration Header"."Trade Type"::Sales then
                        CurrReport.Break;

                    SetFilters(VATEntryPurchase);

                    RecordNo := 0;
                    NoOfRecords := Count;
                    OldTime := Time;
                end;
            }
            dataitem("VAT Posting Setup"; "VAT Posting Setup")
            {
                DataItemTableView = SORTING("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                dataitem(VATEntryAdvance; "VAT Entry")
                {
                    DataItemLink = "VAT Bus. Posting Group" = FIELD("VAT Bus. Posting Group"), "VAT Prod. Posting Group" = FIELD("VAT Prod. Posting Group");
                    DataItemTableView = SORTING(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        UpdateProgressBar;
                        AddVIESLine(VATEntryAdvance);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not IncludingAdvancePayments then
                            CurrReport.Break;

                        SetFilters(VATEntryAdvance);
                        SetRange(Base);
                        SetFilter("Advance Base", '<>%1', 0);

                        RecordNo := 0;
                        NoOfRecords := Count;
                        OldTime := Time;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    SetRange("VIES Sales", true);
                    SetRange("EU Service", true);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "Period No.");
                Window.Update(2, Year);
            end;

            trigger OnPostDataItem()
            begin
                SaveBuffer;
                Window.Close;
            end;

            trigger OnPreDataItem()
            begin
                if GetRangeMin("No.") <> GetRangeMax("No.") then
                    Error(Text006);

                LastLineNo := 0;

                TempVIESLine.DeleteAll;
                TempVIESLine.Reset;
                TransBuffer.DeleteAll;

                if DeleteLines then begin
                    VIESLine.Reset;
                    VIESLine.SetRange("VIES Declaration No.", GetRangeMin("No."));
                    if VIESLine.FindFirst then begin
                        VIESLine.DeleteAll;
                        Commit;
                    end;
                end;

                Window.Open(Text001 + Text002 + Text004);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeleteLines; DeleteLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delete Existing Lines';
                        ToolTip = 'Specifies if existing lines have to be deleted.';
                    }
                    field(IncludingAdvancePayments; IncludingAdvancePayments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Including Advance Payments';
                        ToolTip = 'Specifies if advance letters will be included.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        VIESLine: Record "VIES Declaration Line";
        TempVIESLine: Record "VIES Declaration Line" temporary;
        TransBuffer: Record "VIES Transaction Buffer" temporary;
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewTime: Time;
        OldTime: Time;
        LastLineNo: Integer;
        DeleteLines: Boolean;
        Text001: Label 'Quarter/Month #1##';
        Text004: Label 'Suggesting lines @3@@@@@@@@@@@@@';
        Text002: Label 'Year #2####';
        Text006: Label 'You can process one declaration only.';
        IncludingAdvancePayments: Boolean;

    [Scope('OnPrem')]
    procedure AddBuffer(TransactionNo: Integer)
    begin
        TempVIESLine.SetCurrentKey("Trade Type");
        TempVIESLine.SetRange("Trade Type", VIESLine."Trade Type");
        TempVIESLine.SetRange("Country/Region Code", VIESLine."Country/Region Code");
        TempVIESLine.SetRange("VAT Registration No.", VIESLine."VAT Registration No.");
        TempVIESLine.SetRange("Registration No.", VIESLine."Registration No.");
        TempVIESLine.SetRange("Trade Role Type", VIESLine."Trade Role Type");
        TempVIESLine.SetRange("EU 3-Party Trade", VIESLine."EU 3-Party Trade");
        TempVIESLine.SetRange("EU 3-Party Intermediate Role", VIESLine."EU 3-Party Intermediate Role");
        TempVIESLine.SetRange("EU Service", VIESLine."EU Service");
        if TempVIESLine.FindFirst then begin
            TempVIESLine."Amount (LCY)" += VIESLine."Amount (LCY)";
            UpdateNumberOfSupplies(TempVIESLine, TransactionNo);
            TempVIESLine.Modify;
        end else begin
            LastLineNo += 10000;
            TempVIESLine := VIESLine;
            TempVIESLine."Line No." := LastLineNo;
            UpdateNumberOfSupplies(TempVIESLine, TransactionNo);
            TempVIESLine.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure SaveBuffer()
    begin
        TempVIESLine.Reset;
        VIESLine.SetRange("VIES Declaration No.", "VIES Declaration Header"."No.");
        if VIESLine.FindLast then;
        LastLineNo := VIESLine."Line No.";

        TempVIESLine.SetFilter("Amount (LCY)", '<>%1', 0);
        if TempVIESLine.FindSet then
            repeat
                LastLineNo += 10000;
                VIESLine := TempVIESLine;
                VIESLine."Amount (LCY)" := Round(TempVIESLine."Amount (LCY)", 1, '>');
                VIESLine."Line No." := LastLineNo;
                VIESLine.Insert;
            until TempVIESLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetTradeRoleType(EU3PartyTrade: Boolean): Integer
    begin
        if EU3PartyTrade then
            exit(VIESLine."Trade Role Type"::"Intermediate Trade");
        exit(VIESLine."Trade Role Type"::"Direct Trade");
    end;

    [Scope('OnPrem')]
    procedure UpdateNumberOfSupplies(var VIESLine: Record "VIES Declaration Line"; TransactionNo: Integer)
    begin
        if not TransBuffer.Get(TransactionNo, VIESLine."EU Service") then begin
            VIESLine."Number of Supplies" := VIESLine."Number of Supplies" + 1;
            TransBuffer."Transaction No." := TransactionNo;
            TransBuffer."EU Service" := VIESLine."EU Service";
            TransBuffer.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure IsEUCountry(VATEntry: Record "VAT Entry"): Boolean
    var
        Country: Record "Country/Region";
    begin
        if VATEntry."Country/Region Code" <> '' then begin
            Country.Get(VATEntry."Country/Region Code");
            exit(Country."EU Country/Region Code" <> '');
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure AddVIESLine(VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not IsEUCountry(VATEntry) then
            exit;

        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        if ((VATEntry.Type = VATEntry.Type::Sale) and VATPostingSetup."VIES Sales" or
            (VATEntry.Type = VATEntry.Type::Purchase) and VATPostingSetup."VIES Purchases")
        then
            with VIESLine do begin
                Init;
                "VIES Declaration No." := "VIES Declaration Header"."No.";
                case VATEntry.Type of
                    VATEntry.Type::Sale:
                        "Trade Type" := "Trade Type"::Sale;
                    VATEntry.Type::Purchase:
                        "Trade Type" := "Trade Type"::Purchase;
                end;
                "Country/Region Code" := VATEntry."Country/Region Code";
                "VAT Registration No." := VATEntry."VAT Registration No.";
                "Registration No." := VATEntry."Registration No.";
                if VATEntry."Advance Base" <> 0 then
                    "Amount (LCY)" := -VATEntry."Advance Base"
                else
                    "Amount (LCY)" := -VATEntry.Base;
                "Amount (LCY)" := ExchangeAmount(VATEntry, "Amount (LCY)");
                "EU 3-Party Trade" := VATEntry."EU 3-Party Trade";
                "EU 3-Party Intermediate Role" := VATEntry."EU 3-Party Intermediate Role";
                "Trade Role Type" := GetTradeRoleType(VATEntry."EU 3-Party Trade");
                "EU Service" := VATEntry."EU Service";
                "System-Created" := true;
                AddBuffer(VATEntry."Transaction No.");
            end;
    end;

    [Scope('OnPrem')]
    procedure UpdateProgressBar()
    begin
        RecordNo := RecordNo + 1;
        NewTime := Time;
        if (NewTime - OldTime > 100) or (NewTime < OldTime) then begin
            NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
            if NewProgress <> OldProgress then begin
                OldProgress := NewProgress;
                Window.Update(3, NewProgress)
            end;
            OldTime := Time;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFilters(var VATEntry: Record "VAT Entry")
    begin
        with "VIES Declaration Header" do begin
            case "EU Goods/Services" of
                "EU Goods/Services"::Goods:
                    VATEntry.SetRange("EU Service", false);
                "EU Goods/Services"::Services:
                    VATEntry.SetRange("EU Service", true);
            end;
            VATEntry.SetRange("VAT Date", "Start Date", "End Date");
            VATEntry.SetFilter(Base, '<>%1', 0);
            VATEntry.SetRange("Perform. Country/Region Code", "Perform. Country/Region Code");
        end;
    end;

    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)')]
    local procedure ExchangeAmount(VATEntry: Record "VAT Entry"; AmountAdd: Decimal): Decimal
    var
        PerfCountryCurrExchRate: Record "Perf. Country Curr. Exch. Rate";
    begin
        if "VIES Declaration Header"."Perform. Country/Region Code" = '' then
            exit(AmountAdd);

        with VATEntry do
            exit(PerfCountryCurrExchRate.ExchangeAmount(
                "Posting Date", "Perform. Country/Region Code", "Currency Code", AmountAdd * "Currency Factor"));
    end;
}

