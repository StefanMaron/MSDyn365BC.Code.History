#if not CLEAN18
report 31045 "FA Phys. Inventory List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FAPhysInventoryList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'FA Phys. Inventory List (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0___day_2___month_2___year4___; Format(Today))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(PrintFAValues; PrintFAValues)
            {
            }
            column(NewPagePerGroup; NewPagePerGroup)
            {
            }
            column(GroupByNumber; Format(GroupBy, 0, 2))
            {
            }
            dataitem("Fixed Asset"; "Fixed Asset")
            {
                DataItemTableView = SORTING("No.");
                RequestFilterFields = "No.";
                column(GETFILTERS; GetFilters)
                {
                }
                column(N1; '1. ')
                {
                }
                column(N2; '2. ')
                {
                }
                column(N3; '3. ')
                {
                }
                column(Member_1_; Member[1])
                {
                }
                column(Member_2_; Member[2])
                {
                }
                column(Member_3_; Member[3])
                {
                }
                column(GetGroupHeader; GetGroupHeader)
                {
                }
                column(Fixed_Asset__Serial_No__; "Serial No.")
                {
                }
                column(Fixed_Asset__Responsible_Employee_; "Responsible Employee")
                {
                }
                column(Fixed_Asset__Main_Asset_Component_; "Main Asset/Component")
                {
                }
                column(Fixed_Asset__FA_Location_Code_; "FA Location Code")
                {
                }
                column(Fixed_Asset__FA_Subclass_Code_; "FA Subclass Code")
                {
                }
                column(Fixed_Asset__FA_Class_Code_; "FA Class Code")
                {
                }
                column(Fixed_Asset_Description; Description)
                {
                }
                column(Fixed_Asset__No__; "No.")
                {
                }
                column(Fixed_Asset__Description_2_; "Description 2")
                {
                }
                column(Fixed_Asset__No___Control1470048; "No.")
                {
                }
                column(Fixed_Asset_Description_Control1470050; Description)
                {
                }
                column(Fixed_Asset__Serial_No___Control1470052; "Serial No.")
                {
                }
                column(Qty; Qty)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(FADeprBook_AcquisitionCost; FADeprBook."Acquisition Cost")
                {
                }
                column(FADeprBook_Depreciation; -FADeprBook.Depreciation)
                {
                }
                column(FADeprBook_BookValue; FADeprBook."Book Value")
                {
                }
                column(LineNo; LineNo)
                {
                }
                column(Qty_Control1470073; Qty)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Totals1; Totals[1])
                {
                }
                column(Totals2; -Totals[2])
                {
                }
                column(Totals3; Totals[3])
                {
                }
                column(GetGroupFooter; GetGroupFooter)
                {
                }
                column(Qty_Control1470070; Qty)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(InvtStartDateAndTimeCaption; EmptyString_Control1470013CaptionLbl)
                {
                }
                column(InvtEndDateAndTimeCaption; EmptyString_Control1470014CaptionLbl)
                {
                }
                column(Committee_members_Caption; Committee_members_CaptionLbl)
                {
                }
                column(Line_No_Caption; Line_No_CaptionLbl)
                {
                }
                column(FA_No_Caption; FA_No_CaptionLbl)
                {
                }
                column(FA_DescriptionCaption; FA_DescriptionCaptionLbl)
                {
                }
                column(Serial_No_Caption; Serial_No_CaptionLbl)
                {
                }
                column(QTY_Calc_Caption; QTY_Calc_CaptionLbl)
                {
                }
                column(QTY_Inv_Caption; QTY_Inv_CaptionLbl)
                {
                }
                column(Acquisition_CostCaption; Acquisition_CostCaptionLbl)
                {
                }
                column(DepreciationCaption; DepreciationCaptionLbl)
                {
                }
                column(Book_ValueCaption; Book_ValueCaptionLbl)
                {
                }
                column(EmptyString_Control1470031Caption; EmptyString_Control1470031CaptionLbl)
                {
                }
                column(Fixed_Asset__Serial_No__Caption; FieldCaption("Serial No."))
                {
                }
                column(Fixed_Asset__Responsible_Employee_Caption; FieldCaption("Responsible Employee"))
                {
                }
                column(Fixed_Asset__Main_Asset_Component_Caption; FieldCaption("Main Asset/Component"))
                {
                }
                column(Fixed_Asset__FA_Location_Code_Caption; FieldCaption("FA Location Code"))
                {
                }
                column(Fixed_Asset__FA_Subclass_Code_Caption; FieldCaption("FA Subclass Code"))
                {
                }
                column(Fixed_Asset__FA_Class_Code_Caption; FieldCaption("FA Class Code"))
                {
                }
                column(Fixed_Asset_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Fixed_Asset__No__Caption; FieldCaption("No."))
                {
                }
                column(Date__SignatureCaption; Date__SignatureCaptionLbl)
                {
                }
                column(Date__SignatureCaption_Control1470080; Date__SignatureCaption_Control1470080Lbl)
                {
                }
                column(Approved_by_committee_members_Caption; Approved_by_committee_members_CaptionLbl)
                {
                }
                column(Date__SignatureCaption_Control1470083; Date__SignatureCaption_Control1470083Lbl)
                {
                }
                column(Total__Quantity__Amount__Caption; Total__Quantity__Amount__CaptionLbl)
                {
                }
                column(Approved_by_committee_members_Caption_Control1470041; Approved_by_committee_members_Caption_Control1470041Lbl)
                {
                }
                column(Date__SignatureCaption_Control1470043; Date__SignatureCaption_Control1470043Lbl)
                {
                }
                column(Date__SignatureCaption_Control1470045; Date__SignatureCaption_Control1470045Lbl)
                {
                }
                column(Date__SignatureCaption_Control1470047; Date__SignatureCaption_Control1470047Lbl)
                {
                }
                column(Last_PageCaption; Last_PageCaptionLbl)
                {
                }
                column(GroupExpression; GroupExpression)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not FADeprBook.Get("No.", DeprBookCode) then
                        CurrReport.Skip();
                    FADeprBook.SetRange("FA Posting Date Filter", 0D, DocumentDate);
                    FADeprBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");
                    if (FADeprBook."Disposal Date" > 0D) and (FADeprBook."Disposal Date" < DocumentDate) then
                        FADeprBook."Book Value" := 0;
                    if (FADeprBook."Book Value" = 0) and (not PrintZeroBookValue) then
                        CurrReport.Skip();

                    Totals[1] := FADeprBook."Acquisition Cost";
                    Totals[2] := FADeprBook.Depreciation;
                    Totals[3] := FADeprBook."Book Value";
                    Qty := 1;

                    LineNo := LineNo + 1;

                    case GroupBy of
                        GroupBy::None:
                            GroupExpression := '';
                        GroupBy::"FA Location Code Only":
                            GroupExpression := "FA Location Code";
                        GroupBy::"Responsible and Location":
                            GroupExpression := "Responsible Employee" + "FA Location Code";
                        GroupBy::"FA Location and Responsible":
                            GroupExpression := "FA Location Code" + "Responsible Employee";
                        GroupBy::"Responsible Employee Only":
                            GroupExpression := "Responsible Employee";
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Qty := 0;
                    LineNo := 0;
                    case GroupBy of
                        GroupBy::"FA Location Code Only",
                      GroupBy::"FA Location and Responsible":
                            SetCurrentKey("FA Location Code", "Responsible Employee");
                        GroupBy::"Responsible Employee Only",
                      GroupBy::"Responsible and Location":
                            SetCurrentKey("Responsible Employee", "FA Location Code");
                    end;
                    Clear(Totals);
                    Clear(Qty);
                end;
            }
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
                    field(DeprBookCode; DeprBookCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book for the printing of entries.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number for the list.';
                    }
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies a document date for the list.';
                    }
                    field(PrintFAValues; PrintFAValues)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print FA Values';
                        ToolTip = 'Specifies to print fixed asset values.';
                    }
                    field(PrintZeroBookValue; PrintZeroBookValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print FA with Zero Book Value';
                        ToolTip = 'Specifies to print fixed assets with zero book values.';
                    }
                    field(GroupBy; GroupBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group By';
                        OptionCaption = 'None,FA Location Code Only,Responsible Employee Only,FA Location and Responsible,Responsible and Location';
                        ToolTip = 'Specifies how fixed assets should be grouped.';
                    }
                    field(NewPagePerGroup; NewPagePerGroup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page Per Group';
                        ToolTip = 'Specifies if you want the report to print a new page for each group.';
                    }
                    field("Member[1]"; Member[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '1. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';
                    }
                    field("Member[2]"; Member[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '2. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';
                    }
                    field("Member[3]"; Member[3])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '3. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';
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

    trigger OnPreReport()
    begin
        if DeprBookCode = '' then
            Error(DeprBookErr);

        if DocumentNo <> '' then
            HeaderText := StrSubstNo(DocumentTxt, DocumentNo)
        else
            HeaderText := ListTxt;

        NewPagePerGroup := GroupBy <> GroupBy::None;
    end;

    var
        FADeprBook: Record "FA Depreciation Book";
        PrintFAValues: Boolean;
        DocumentNo: Code[10];
        LineNo: Integer;
        Qty: Decimal;
        HeaderText: Text[60];
        DeprBookCode: Code[10];
        Totals: array[3] of Decimal;
        GroupBy: Option "None","FA Location Code Only","Responsible Employee Only","FA Location and Responsible","Responsible and Location";
        Member: array[3] of Text[100];
        DocumentDate: Date;
        PrintZeroBookValue: Boolean;
        GroupExpression: Code[30];
        ListTxt: Label 'Phys. Fixed Assets List';
        DocumentTxt: Label 'FIXED ASSET PHYSICAL INVENTORY DOCUMENT No. %1';
        DeprBookErr: Label 'Depreciation Book Code must not be empty.';
        TotalTxt: Label 'Totals for';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        EmptyString_Control1470013CaptionLbl: Label 'Stocktaking begin date/ time';
        EmptyString_Control1470014CaptionLbl: Label 'Stocktaking end date/ time';
        Committee_members_CaptionLbl: Label 'Committee members:';
        Line_No_CaptionLbl: Label 'Line No.';
        FA_No_CaptionLbl: Label 'FA No.';
        FA_DescriptionCaptionLbl: Label 'FA Description';
        Serial_No_CaptionLbl: Label 'Serial No.';
        QTY_Calc_CaptionLbl: Label 'QTY Calc.';
        QTY_Inv_CaptionLbl: Label 'QTY Inventory';
        Acquisition_CostCaptionLbl: Label 'Acquisition Cost';
        DepreciationCaptionLbl: Label 'Depreciation';
        Book_ValueCaptionLbl: Label 'Book Value';
        EmptyString_Control1470031CaptionLbl: Label 'Quantity';
        Date__SignatureCaptionLbl: Label 'Date, Signature';
        Date__SignatureCaption_Control1470080Lbl: Label 'Date, Signature';
        Approved_by_committee_members_CaptionLbl: Label 'Approved by committee members:';
        Date__SignatureCaption_Control1470083Lbl: Label 'Date, Signature';
        Total__Quantity__Amount__CaptionLbl: Label 'Total (Quantity, Amount):';
        Approved_by_committee_members_Caption_Control1470041Lbl: Label 'Approved by committee members:';
        Date__SignatureCaption_Control1470043Lbl: Label 'Date, Signature';
        Date__SignatureCaption_Control1470045Lbl: Label 'Date, Signature';
        Date__SignatureCaption_Control1470047Lbl: Label 'Date, Signature';
        Last_PageCaptionLbl: Label 'Last Page';
        NewPagePerGroup: Boolean;

    [Scope('OnPrem')]
    procedure GetGroupHeader(): Text[100]
    begin
        case GroupBy of
            GroupBy::"FA Location Code Only":
                exit(
                  StrSubstNo('%1: %2',
                    "Fixed Asset".FieldCaption("FA Location Code"), "Fixed Asset"."FA Location Code"));
            GroupBy::"Responsible Employee Only":
                exit(
                  StrSubstNo('%1: %2',
                    "Fixed Asset".FieldCaption("Responsible Employee"), "Fixed Asset"."Responsible Employee"));
            GroupBy::"FA Location and Responsible":
                exit(
                  StrSubstNo('%1: %2, %3: %4',
                    "Fixed Asset".FieldCaption("FA Location Code"), "Fixed Asset"."FA Location Code",
                    "Fixed Asset".FieldCaption("Responsible Employee"), "Fixed Asset"."Responsible Employee"));
            GroupBy::"Responsible and Location":
                exit(
                  StrSubstNo('%1: %2, %3: %4',
                    "Fixed Asset".FieldCaption("Responsible Employee"), "Fixed Asset"."Responsible Employee",
                    "Fixed Asset".FieldCaption("FA Location Code"), "Fixed Asset"."FA Location Code"));
            else
                exit('');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetGroupFooter(): Text[100]
    begin
        case GroupBy of
            GroupBy::"FA Location Code Only":
                exit(
                  StrSubstNo('%1 %2: %3', TotalTxt,
                    "Fixed Asset".FieldCaption("FA Location Code"), "Fixed Asset"."FA Location Code"));
            GroupBy::"Responsible Employee Only":
                exit(
                  StrSubstNo('%1 %2: %3', TotalTxt,
                    "Fixed Asset".FieldCaption("Responsible Employee"), "Fixed Asset"."Responsible Employee"));
            GroupBy::"FA Location and Responsible":
                exit(
                  StrSubstNo('%1 %2: %3, %4: %5', TotalTxt,
                    "Fixed Asset".FieldCaption("FA Location Code"), "Fixed Asset"."FA Location Code",
                    "Fixed Asset".FieldCaption("Responsible Employee"), "Fixed Asset"."Responsible Employee"));
            GroupBy::"Responsible and Location":
                exit(
                  StrSubstNo('%1 %2: %3, %4: %5', TotalTxt,
                    "Fixed Asset".FieldCaption("Responsible Employee"), "Fixed Asset"."Responsible Employee",
                    "Fixed Asset".FieldCaption("FA Location Code"), "Fixed Asset"."FA Location Code"));
            else
                exit('');
        end;
    end;
}
#endif