#if not CLEAN18
report 31049 "FA History"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FAHistory.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'FA History (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem(Header; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            PrintOnlyIfDetail = true;
            column(STRSUBSTNO_Text000_FORMAT_EndDate__; StrSubstNo(AtDateLbl, Format(EndDate)))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(GroupBy; Format(GroupBy))
            {
            }
            column(GroupByText; GroupBy)
            {
                OptionCaption = ' ,Location,Responsible Employee';
                OptionMembers = " ",Location,"Responsible Employee";
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(GroupByCaption; GroupByCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(FA_HistoryCaption; FA_HistoryCaptionLbl)
            {
            }
            column(NewPagePerGroup; NewPagePerGroup)
            {
            }
            dataitem(FAHistory; "FA History Entry")
            {
                RequestFilterFields = "FA No.", "Creation Date", Type, "New Value", "Old Value";
                column(FAHistory__Entry_No__; "Entry No.")
                {
                }
                column(FAHistory_Type; Type)
                {
                }
                column(FAHistory__FA_No__; "FA No.")
                {
                }
                column(FAHistory__Old_Value_; "Old Value")
                {
                }
                column(FAHistory__New_Value_; "New Value")
                {
                }
                column(FAHistory__Creation_Date_; "Creation Date")
                {
                }
                column(FAHistory__Creation_Time_; "Creation Time")
                {
                }
                column(FAHistory__User_ID_; "User ID")
                {
                }
                column(FAHistory_TypeCaption; FieldCaption(Type))
                {
                }
                column(FAHistory__FA_No__Caption; FieldCaption("FA No."))
                {
                }
                column(FAHistory__Old_Value_Caption; FieldCaption("Old Value"))
                {
                }
                column(FAHistory__Creation_Time_Caption; FieldCaption("Creation Time"))
                {
                }
                column(FAHistory__Creation_Date_Caption; FieldCaption("Creation Date"))
                {
                }
                column(FAHistory__New_Value_Caption; FieldCaption("New Value"))
                {
                }
                column(FAHistory__Entry_No__Caption; FieldCaption("Entry No."))
                {
                }
                column(FAHistory__User_ID_Caption; FieldCaption("User ID"))
                {
                }

                trigger OnPreDataItem()
                begin
                    if GroupBy <> GroupBy::" " then
                        CurrReport.Break();
                end;
            }
            dataitem(FALoc; "FA Location")
            {
                DataItemTableView = SORTING(Code);
                PrintOnlyIfDetail = true;
                column(FALoc_NameCaption; FALoc_NameCaptionLbl)
                {
                }
                column(FALoc_Code_Control1470042Caption; FALoc_Code_Control1470042CaptionLbl)
                {
                }
                column(FALoc_Code; Code)
                {
                }
                dataitem(FA; "Fixed Asset")
                {
                    DataItemTableView = SORTING("No.") ORDER(Descending);
                    PrintOnlyIfDetail = true;
                    column(FA_No_; "No.")
                    {
                    }
                    dataitem(FAHistory2; "FA History Entry")
                    {
                        DataItemTableView = SORTING("FA No.", "Entry No.") ORDER(Descending) WHERE(Type = CONST(Location));
                        PrintOnlyIfDetail = false;
                        column(FALoc_Name; FALoc.Name)
                        {
                        }
                        column(FALoc_Code_Control1470042; FALoc.Code)
                        {
                        }
                        column(FAHistory2__FA_No__; "FA No.")
                        {
                        }
                        column(FAHistory2__Creation_Date_; "Creation Date")
                        {
                        }
                        column(FAHistory2__Creation_Time_; "Creation Time")
                        {
                        }
                        column(FAHistory2__Old_Value_; "Old Value")
                        {
                        }
                        column(Description; Description)
                        {
                        }
                        column(SerialNo; SerialNo)
                        {
                        }
                        column(FAHistory2__User_ID_; "User ID")
                        {
                        }
                        column(No_Caption; No_CaptionLbl)
                        {
                        }
                        column(DescriptionCaption; DescriptionCaptionLbl)
                        {
                        }
                        column(SerialNoCaption; SerialNoCaptionLbl)
                        {
                        }
                        column(Old_LocationCaption; Old_LocationCaptionLbl)
                        {
                        }
                        column(Change_DateCaption; Change_DateCaptionLbl)
                        {
                        }
                        column(Change_TimeCaption; Change_TimeCaptionLbl)
                        {
                        }
                        column(FAHistory2__User_ID_Caption; FieldCaption("User ID"))
                        {
                        }
                        column(FAHistory2_Entry_No_; "Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if FirstTime then begin
                                TempFAHistory.Reset();
                                TempFAHistory.CopyFilters(FAHistory);
                                TempFAHistory.SetRange(Type, TempFAHistory.Type::Location);
                                if FAHistory.GetFilter("Creation Date") = '' then
                                    TempFAHistory.SetRange("Creation Date", 0D, EndDate);
                                TempFAHistory.SetRange("FA No.", FA."No.");
                                ShowFirstHead := FindFirstFA(FALoc.Code, false);

                                FirstTime := false;

                                if CountPerGroup = 0 then begin
                                    if not ShowFirstHead then
                                        CountPerGroup := 0
                                    else begin
                                        CountPerGroup := CountPerGroup + 1;
                                        GroupCount := GroupCount + 1;
                                    end;
                                end else
                                    CountPerGroup := CountPerGroup + 1;
                            end;

                            if Disposal then begin
                                if not CheckCancel then
                                    CurrReport.Break();
                                CurrReport.Skip();
                            end;
                            if "Closed by Entry No." <> 0 then begin
                                CheckCancel := true;
                                CurrReport.Skip();
                            end;

                            if "New Value" <> FALoc.Code then
                                CurrReport.Break();

                            TestField("FA No.");
                            if FA3.Get("FA No.") then begin
                                Description := FA3.Description;
                                SerialNo := FA3."Serial No.";
                            end;

                            if FANo <> "FA No." then begin
                                FANo := "FA No.";
                                TempFAHistory.Reset();
                                TempFAHistory.CopyFilters(FAHistory);
                                if FAHistory.GetFilter("Creation Date") = '' then
                                    TempFAHistory.SetRange("Creation Date", 0D, EndDate);

                                if FAHistory.GetFilter("Entry No.") = '' then begin
                                    TempFAHistory.SetRange("Entry No.", "Entry No.");
                                    if not TempFAHistory.FindFirst then
                                        CurrReport.Break();
                                end else
                                    if FAHistory.GetFilter("Entry No.") <> Format("Entry No.") then
                                        CurrReport.Break();
                            end else
                                CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetFilter("FA No.", FA."No.");
                            SetRange("Creation Date", 0D, EndDate);
                            FirstTime := true;
                            ShowFirstHead := false;
                            CheckCancel := false;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempFAHistory.Reset();
                        TempFAHistory.SetFilter("FA No.", "No.");
                        TempFAHistory.SetRange(Type, TempFAHistory.Type::Location);
                        if not TempFAHistory.FindFirst then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if FAHistory.GetFilter("FA No.") <> '' then
                            FAHistory.CopyFilter("FA No.", "No.");

                        CountPerGroup := 0;
                        FANo := '';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempFAHistory.Reset();
                    TempFAHistory.SetFilter("New Value", Code);
                    TempFAHistory.SetRange(Type, TempFAHistory.Type::Location);
                    if not TempFAHistory.FindFirst then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if GroupBy <> GroupBy::Location then
                        CurrReport.Break();

                    if FAHistory.GetFilter("New Value") <> '' then
                        FAHistory.CopyFilter("New Value", Code);

                    GroupCount := 0;

                    TempFAHistory.Reset();
                    TempFAHistory.CopyFilters(FAHistory);
                    TempFAHistory.SetRange(Type, TempFAHistory.Type::Location);
                    if FAHistory.GetFilter("Creation Date") = '' then
                        TempFAHistory.SetRange("Creation Date", 0D, EndDate);
                end;
            }
            dataitem(Employee; Employee)
            {
                DataItemTableView = SORTING("No.");
                PrintOnlyIfDetail = true;
                column(First_NameCaption; First_NameCaptionLbl)
                {
                }
                column(No_Caption_Control1470051; No_Caption_Control1470051Lbl)
                {
                }
                column(Last_NameCaption; Last_NameCaptionLbl)
                {
                }
                column(Employee_No_; "No.")
                {
                }
                dataitem(FA2; "Fixed Asset")
                {
                    DataItemTableView = SORTING("No.") ORDER(Descending);
                    PrintOnlyIfDetail = true;
                    column(FA2_No_; "No.")
                    {
                    }
                    dataitem(FAHistory3; "FA History Entry")
                    {
                        DataItemTableView = SORTING("FA No.", "Entry No.") ORDER(Descending) WHERE(Type = CONST("Responsible Employee"));
                        column(Employee__No__; Employee."No.")
                        {
                        }
                        column(Employee__First_Name_; Employee."First Name")
                        {
                        }
                        column(Employee__Last_Name_; Employee."Last Name")
                        {
                        }
                        column(FAHistory3__FA_No__; "FA No.")
                        {
                        }
                        column(Description_Control1470072; Description)
                        {
                        }
                        column(SerialNo_Control1470073; SerialNo)
                        {
                        }
                        column(FAHistory3__Creation_Date_; "Creation Date")
                        {
                        }
                        column(FAHistory3__Creation_Time_; "Creation Time")
                        {
                        }
                        column(FAHistory3__User_ID_; "User ID")
                        {
                        }
                        column(PreviousEmployee; PreviousEmployee)
                        {
                        }
                        column(FAHistory3__FA_No__Caption; FAHistory3__FA_No__CaptionLbl)
                        {
                        }
                        column(DescriptionCaption_Control1470065; DescriptionCaption_Control1470065Lbl)
                        {
                        }
                        column(SerialNo_Control1470073Caption; SerialNo_Control1470073CaptionLbl)
                        {
                        }
                        column(Change_DateCaption_Control1470067; Change_DateCaption_Control1470067Lbl)
                        {
                        }
                        column(FAHistory3__Creation_Time_Caption; FAHistory3__Creation_Time_CaptionLbl)
                        {
                        }
                        column(FAHistory3__User_ID_Caption; FieldCaption("User ID"))
                        {
                        }
                        column(PreviousEmployeeCaption; PreviousEmployeeCaptionLbl)
                        {
                        }
                        column(FAHistory3_Entry_No_; "Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if FirstTime then begin
                                TempFAHistory.Reset();
                                TempFAHistory.CopyFilters(FAHistory);
                                TempFAHistory.SetRange(Type, TempFAHistory.Type::"Responsible Employee");
                                if FAHistory.GetFilter("Creation Date") = '' then
                                    TempFAHistory.SetRange("Creation Date", 0D, EndDate);
                                TempFAHistory.SetRange("FA No.", FA2."No.");
                                ShowFirstHead := FindFirstFA(Employee."No.", false);

                                FirstTime := false;

                                if CountPerGroup = 0 then begin
                                    if not ShowFirstHead then
                                        CountPerGroup := 0
                                    else begin
                                        CountPerGroup := CountPerGroup + 1;
                                        GroupCount := GroupCount + 1;
                                    end;
                                end else
                                    CountPerGroup := CountPerGroup + 1;
                            end;

                            if Disposal then begin
                                if not CheckCancel then
                                    CurrReport.Break();
                                CurrReport.Skip();
                            end;
                            if "Closed by Entry No." <> 0 then begin
                                CheckCancel := true;
                                CurrReport.Skip();
                            end;

                            if "New Value" <> Employee."No." then
                                CurrReport.Break();

                            TestField("FA No.");
                            if FA3.Get("FA No.") then begin
                                Description := FA3.Description;
                                SerialNo := FA3."Serial No.";
                            end;

                            if FANo <> "FA No." then begin
                                FANo := "FA No.";
                                TempFAHistory.Reset();
                                TempFAHistory.CopyFilters(FAHistory);
                                if FAHistory.GetFilter("Creation Date") = '' then
                                    TempFAHistory.SetRange("Creation Date", 0D, EndDate);

                                if FAHistory.GetFilter("Entry No.") = '' then begin
                                    TempFAHistory.SetRange("Entry No.", "Entry No.");
                                    if not TempFAHistory.FindFirst then
                                        CurrReport.Break();
                                end else
                                    if FAHistory.GetFilter("Entry No.") <> Format("Entry No.") then
                                        CurrReport.Break();
                            end else
                                CurrReport.Break();

                            if "Old Value" <> '' then begin
                                TempEmployee.Get("Old Value");
                                PreviousEmployee := "Old Value" + ' ' + TempEmployee.FullName;
                            end else
                                PreviousEmployee := '';
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetFilter("FA No.", FA2."No.");
                            SetRange("Creation Date", 0D, EndDate);

                            FirstTime := true;
                            ShowFirstHead := false;
                            CheckCancel := false;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempFAHistory.Reset();
                        TempFAHistory.SetFilter("FA No.", "No.");
                        TempFAHistory.SetRange(Type, TempFAHistory.Type::"Responsible Employee");
                        if not TempFAHistory.FindFirst then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if FAHistory.GetFilter("FA No.") <> '' then
                            FAHistory.CopyFilter("FA No.", "No.");

                        CountPerGroup := 0;
                        FANo := '';
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempFAHistory.Reset();
                    TempFAHistory.SetFilter("New Value", "No.");
                    TempFAHistory.SetRange(Type, TempFAHistory.Type::"Responsible Employee");
                    if not TempFAHistory.FindFirst then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if GroupBy <> GroupBy::"Responsible Employee" then
                        CurrReport.Break();

                    if FAHistory.GetFilter("New Value") <> '' then
                        FAHistory.CopyFilter("New Value", "No.");

                    GroupCount := 0;

                    TempFAHistory.Reset();
                    TempFAHistory.CopyFilters(FAHistory);
                    TempFAHistory.SetRange(Type, TempFAHistory.Type::"Responsible Employee");
                    if FAHistory.GetFilter("Creation Date") = '' then
                        TempFAHistory.SetRange("Creation Date", 0D, EndDate);
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
                    field(GroupBy; GroupBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group By';
                        OptionCaption = ' ,Location,Responsible Employee';
                        ToolTip = 'Specifies how fixed assets should be grouped.';

                        trigger OnValidate()
                        begin
                            CheckMarkEnable := GroupBy <> GroupBy::" ";
                        end;
                    }
                    field(NewPagePerGroup; NewPagePerGroup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page Per Group';
                        Enabled = CheckMarkEnable;
                        ToolTip = 'Specifies if you want the report to print a new page for each group.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'As of Date';
                        ToolTip = 'Specifies the date that the history will be based on in MMDDYY format.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CheckMarkEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if EndDate = 0D then
                EndDate := WorkDate;

            CheckMarkEnable := GroupBy <> GroupBy::" ";
        end;
    }

    labels
    {
    }

    var
        FA3: Record "Fixed Asset";
        TempFAHistory: Record "FA History Entry";
        TempEmployee: Record Employee;
        GroupBy: Option " ",Location,"Responsible Employee";
        EndDate: Date;
        FANo: Code[20];
        Description: Text[100];
        SerialNo: Text[50];
        NewPagePerGroup: Boolean;
        FirstTime: Boolean;
        ShowFirstHead: Boolean;
        CheckCancel: Boolean;
        GroupCount: Integer;
        CountPerGroup: Integer;
        PreviousEmployee: Text[50];
        [InDataSet]
        CheckMarkEnable: Boolean;
        AtDateLbl: Label 'As of %1';
        FA_HistoryCaptionLbl: Label 'FA History';
        GroupByCaptionLbl: Label 'Group by';
        PageCaptionLbl: Label 'Page';
        FALoc_NameCaptionLbl: Label 'Name';
        FALoc_Code_Control1470042CaptionLbl: Label 'Code';
        No_CaptionLbl: Label 'No.';
        DescriptionCaptionLbl: Label 'Description';
        SerialNoCaptionLbl: Label 'Serial No.';
        Old_LocationCaptionLbl: Label 'Old Location';
        Change_DateCaptionLbl: Label 'Change Date';
        Change_TimeCaptionLbl: Label 'Change Time';
        First_NameCaptionLbl: Label 'First Name';
        No_Caption_Control1470051Lbl: Label 'No.';
        Last_NameCaptionLbl: Label 'Last Name';
        FAHistory3__FA_No__CaptionLbl: Label 'No.';
        DescriptionCaption_Control1470065Lbl: Label 'Description';
        SerialNo_Control1470073CaptionLbl: Label 'Serial No.';
        Change_DateCaption_Control1470067Lbl: Label 'Change Date';
        FAHistory3__Creation_Time_CaptionLbl: Label 'Change Time';
        PreviousEmployeeCaptionLbl: Label 'Previous Employee';

    [Scope('OnPrem')]
    procedure FindFA(FANo: Code[20]; FAType: Option Location,"Responsible Employee"; No: Code[20]; EntryNo: Integer) OK: Boolean
    var
        DisposalCancelled: Boolean;
    begin
        with TempFAHistory do begin
            Reset;
            OK := false;
            DisposalCancelled := false;
            SetCurrentKey("FA No.");
            SetRange(Type, FAType);
            SetRange("FA No.", FANo);
            SetRange("Creation Date", 0D, EndDate);
            if FindLast then
                repeat
                    if Disposal then begin
                        if not DisposalCancelled then
                            exit;
                    end else
                        DisposalCancelled := ("Closed by Entry No." <> 0);
                    if not DisposalCancelled and
                       ("New Value" = No) and
                       ("Entry No." = EntryNo) and
                       ("New Value" <> '')
                    then begin
                        OK := true;
                        exit;
                    end;
                    if not DisposalCancelled then
                        exit;
                until Next(-1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindFirstFA(TypeCode: Code[20]; IsWholeTable: Boolean) OK: Boolean
    var
        TempFAHistory2: Record "FA History Entry";
    begin
        TempFAHistory2.Reset();
        TempFAHistory2.CopyFilters(TempFAHistory);
        OK := false;
        if TempFAHistory2.FindSet then
            repeat
                if IsWholeTable then
                    TypeCode := TempFAHistory2."New Value";
                OK := FindFA(TempFAHistory2."FA No.", TempFAHistory2.Type, TypeCode, TempFAHistory2."Entry No.");
                if OK then
                    exit;
            until TempFAHistory2.Next() = 0;
    end;
}
#endif