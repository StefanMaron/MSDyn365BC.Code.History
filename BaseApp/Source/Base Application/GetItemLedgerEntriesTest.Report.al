report 31059 "Get Item Ledger Entries - Test"
{
    // //CO4.20: Controling - Basic: Intrastat CZ modification;
    // //CO4.20: Controling - Basic: Partner Registration More Country;
    DefaultLayout = RDLC;
    RDLCLayout = './GetItemLedgerEntriesTest.rdlc';

    Caption = 'Get Item Ledger Entries - Test';
    Permissions = TableData "General Posting Setup" = imd;

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = SORTING("Intrastat Code") WHERE("Intrastat Code" = FILTER(<> ''));
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Country/Region Code" = FIELD(Code);
                DataItemTableView = SORTING("Country/Region Code", "Entry Type", "Posting Date") WHERE("Entry Type" = FILTER(Purchase | Sale | Transfer));

                trigger OnAfterGetRecord()
                begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Entry No.");
                    if IntrastatJnlLine2.FindFirst or
                       (("Perform. Country/Region Code" = '') and (CompanyInfo."Country/Region Code" = "Country/Region Code")) or
                       (("Perform. Country/Region Code" <> '') and ("Country/Region Code" = "Perform. Country/Region Code"))
                    then
                        CurrReport.Skip;

                    if Item."No." <> "Item No." then
                        Item.Get("Item No.");

                    if Item."Tariff No." = '' then
                        if not greTItem.Get(Item."No.") then begin
                            greTItem.Init;
                            greTItem."No." := Item."No.";
                            greTItem.Description := Item.Description;
                            greTItem.Insert;
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", StartDate, EndDate);
                    if gcoCountryCodeFillFiter <> '' then
                        SetRange("Perform. Country/Region Code", gcoCountryCodeFillFiter)
                    else
                        SetRange("Perform. Country/Region Code", '');

                    IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                    IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"Item Entry");
                end;
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemLink = "Country/Region Code" = FIELD(Code);
                DataItemTableView = SORTING(Type, "Entry Type", "Country/Region Code", "Source Code", "Posting Date") WHERE(Type = CONST(Item), "Source Code" = FILTER(<> ''));

                trigger OnAfterGetRecord()
                begin
                    IntrastatJnlLine2.SetRange("Source Entry No.", "Entry No.");
                    if IntrastatJnlLine2.FindFirst or (CompanyInfo."Country/Region Code" = "Country/Region Code") then
                        CurrReport.Skip;

                    if Item."No." <> "No." then
                        Item.Get("No.");

                    if Item."Tariff No." = '' then
                        if not greTItem.Get(Item."No.") then begin
                            greTItem.Init;
                            greTItem."No." := Item."No.";
                            greTItem.Description := Item.Description;
                            greTItem.Insert;
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", StartDate, EndDate);
                    IntrastatJnlLine2.SetCurrentKey("Source Type", "Source Entry No.");
                    IntrastatJnlLine2.SetRange("Source Type", IntrastatJnlLine2."Source Type"::"Job Entry");
                end;
            }
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            column(USERID; UserId)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(greTItem__No__; greTItem."No.")
            {
            }
            column(greTItem_Description; greTItem.Description)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Get_Item_Ledger_Entries___TestCaption; Get_Item_Ledger_Entries___TestCaptionLbl)
            {
            }
            column(greTItem__No__Caption; greTItem__No__CaptionLbl)
            {
            }
            column(greTItem_DescriptionCaption; greTItem_DescriptionCaptionLbl)
            {
            }
            column(Tariff_No__must_be_enter_on_Item_card_Caption; Tariff_No__must_be_enter_on_Item_card_CaptionLbl)
            {
            }
            column(Integer_Number; Number)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number <> 1 then
                    greTItem.Next;
            end;

            trigger OnPreDataItem()
            begin
                if not greTItem.Find('-') then
                    CurrReport.Break;
                SetRange(Number, 1, greTItem.Count);
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date in the period.';
                    }
                    field(gcoCountryCodeFillFiter; gcoCountryCodeFillFiter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Performance Country';
                        TableRelation = "Country/Region";
                        ToolTip = 'Specifies performance country code for VAT entries filtr.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            IntraJnlTemplate.Get(IntrastatJnlLine."Journal Template Name");
            IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
            IntrastatJnlBatch.TestField("Statistics Period");
            Century := Date2DMY(WorkDate, 3) div 100;
            Evaluate(Year, CopyStr(IntrastatJnlBatch."Statistics Period", 1, 2));
            Year := Year + Century * 100;
            Evaluate(Month, CopyStr(IntrastatJnlBatch."Statistics Period", 3, 2));
            StartDate := DMY2Date(1, Month, Year);
            EndDate := CalcDate('<+1M-1D>', StartDate);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get;
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlLine2: Record "Intrastat Jnl. Line";
        Item: Record Item;
        CompanyInfo: Record "Company Information";
        greTItem: Record Item temporary;
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)')]
        gcoCountryCodeFillFiter: Code[10];
        StartDate: Date;
        EndDate: Date;
        Century: Integer;
        Year: Integer;
        Month: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Get_Item_Ledger_Entries___TestCaptionLbl: Label 'Get Item Ledger Entries - Test';
        greTItem__No__CaptionLbl: Label 'No.';
        greTItem_DescriptionCaptionLbl: Label 'Description';
        Tariff_No__must_be_enter_on_Item_card_CaptionLbl: Label 'Tariff No. must be enter on Item card!';

    [Scope('OnPrem')]
    procedure SetIntrastatJnlLine(NewIntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine := NewIntrastatJnlLine;
    end;
}

