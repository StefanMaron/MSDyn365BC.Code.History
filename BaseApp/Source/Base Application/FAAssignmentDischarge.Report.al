report 31039 "FA Assignment/Discharge"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FAAssignmentDischarge.rdlc';
    Caption = 'FA Assignment/Discharge';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("FA History Entry"; "FA History Entry")
        {
            DataItemTableView = SORTING("Entry No.") WHERE("Closed by Entry No." = CONST(0));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Entry No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PageNo; PageNo)
            {
            }
            column(USERID; UserId)
            {
            }
            column(FA_History_Entry_Entry_No_; "Entry No.")
            {
            }
            column(PrintDate; PrintDate)
            {
            }
            dataitem(Dicharge; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(0));
                PrintOnlyIfDetail = true;
                column(ReportType; ReportType)
                {
                }
                column(FA_History_Entry__Type; "FA History Entry".Type)
                {
                    OptionCaption = 'Location,Responsible Employee';
                }
                column(FirstName; FirstName)
                {
                }
                column(FirstName2; FirstName2)
                {
                }
                column(LastName; LastName)
                {
                }
                column(LastName2; LastName2)
                {
                }
                column("Code"; Code)
                {
                }
                column(PageNoCaption; PageNoCaptionLbl)
                {
                }
                column(CodeCaption; CodeCaptionLbl)
                {
                }
                column(Dicharge_Number; Number)
                {
                }
                dataitem("FA History Entry1"; "FA History Entry")
                {
                    DataItemTableView = SORTING("Entry No.");
                    column(FA_History_Entry1__Creation_Date_; "Creation Date")
                    {
                    }
                    column(FA_History_Entry1__FA_No__; "FA No.")
                    {
                    }
                    column(Description; Description)
                    {
                    }
                    column(SerialNo; SerialNo)
                    {
                    }
                    column(Text006; Text006CaptionLbl)
                    {
                    }
                    column(Text006_Control1470022; Text006_Control1470022CaptionLbl)
                    {
                    }
                    column(Text006_Control1470024; Text006_Control1470024CaptionLbl)
                    {
                    }
                    column(Date_DischargedCaption; Date_DischargedCaptionLbl)
                    {
                    }
                    column(FA_History_Entry1__FA_No__Caption; FA_History_Entry1__FA_No__CaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(SerialNoCaption; SerialNoCaptionLbl)
                    {
                    }
                    column(Text006Caption; Text006CaptionLbl)
                    {
                    }
                    column(Text006_Control1470022Caption; Text006_Control1470022CaptionLbl)
                    {
                    }
                    column(Text006_Control1470024Caption; Text006_Control1470024CaptionLbl)
                    {
                    }
                    column(FA_History_Entry1_Entry_No_; "Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Copy("FA History Entry");
                        if ShowReport(ReportCount) then
                            CurrReport.Break;
                    end;

                    trigger OnPreDataItem()
                    begin
                        CopyFilters("FA History Entry");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    ReportType := Text005Cap;
                    PrintDate := Format(Today, 0, 4);
                    if "FA History Entry".Type = "FA History Entry".Type::Location then begin
                        if FALocation.FindLast then begin
                            Code := FALocation.Code;
                            FirstName := Text001Cap;
                            FirstName2 := FALocation.Name;
                            LastName := '';
                            LastName2 := '';
                        end else
                            if ShowFlag then begin
                                Code := '';
                                FirstName := Text001Cap;
                                FirstName2 := '';
                                LastName := '';
                                LastName2 := '';
                            end else
                                CurrReport.Break;
                    end else begin
                        if Employee.FindLast then begin
                            Code := Employee."No.";
                            FirstName := Text002Cap;
                            FirstName2 := Employee."First Name";
                            LastName := Text003Cap;
                            LastName2 := Employee."Last Name";
                        end else
                            if ShowFlag then begin
                                Code := '';
                                FirstName := Text002Cap;
                                FirstName2 := '';
                                LastName := Text003Cap;
                                LastName2 := '';
                            end else
                                CurrReport.Break;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if "FA History Entry".Type = "FA History Entry".Type::Location then
                        FALocation.SetRange(Code, "FA History Entry"."Old Value")
                    else
                        Employee.SetRange("No.", "FA History Entry"."Old Value");

                    if "FA History Entry"."New Value" = '' then
                        ShowFlag := true;

                    PrintDate := Format(Today, 0, 4);
                    PageNo := CurrReport.PageNo;
                end;
            }
            dataitem(Assignment; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(0));
                PrintOnlyIfDetail = true;
                column(ReportType_Control1470026; ReportType)
                {
                }
                column(COMPANYNAME_Control1470027; COMPANYPROPERTY.DisplayName)
                {
                }
                column(PrintDate_Control1470028; PrintDate)
                {
                }
                column(PageCaption; PageCaption)
                {
                }
                column(PageNo_Control1470030; PageNo)
                {
                }
                column(FA_History_Entry__Type_Control1470031; "FA History Entry".Type)
                {
                    OptionCaption = 'Location,Responsible Employee';
                }
                column(LastName_Control1470032; LastName)
                {
                }
                column(LastName2_Control1470033; LastName2)
                {
                }
                column(FirstName_Control1470034; FirstName)
                {
                }
                column(FirstName2_Control1470035; FirstName2)
                {
                }
                column(Code_Control1470036; Code)
                {
                }
                column(Code_Control1470036Caption; Code_Control1470036CaptionLbl)
                {
                }
                column(Assignment_Number; Number)
                {
                }
                dataitem("FA History Entry2"; "FA History Entry")
                {
                    DataItemTableView = SORTING("Entry No.");
                    column(FA_History_Entry2__Creation_Date_; "Creation Date")
                    {
                    }
                    column(FA_History_Entry2__FA_No__; "FA No.")
                    {
                    }
                    column(SerialNo_Control1470042; SerialNo)
                    {
                    }
                    column(Description_Control1470044; Description)
                    {
                    }
                    column(Text006_Control1470046; Text006Cap)
                    {
                    }
                    column(Text006_Control1470048; Text006Cap)
                    {
                    }
                    column(Text006_Control1470050; Text006Cap)
                    {
                    }
                    column(Date_AssignedCaption; Date_AssignedCaptionLbl)
                    {
                    }
                    column(FA_History_Entry2__FA_No__Caption; FA_History_Entry2__FA_No__CaptionLbl)
                    {
                    }
                    column(SerialNo_Control1470042Caption; SerialNo_Control1470042CaptionLbl)
                    {
                    }
                    column(Description_Control1470044Caption; Description_Control1470044CaptionLbl)
                    {
                    }
                    column(Text006_Control1470046Caption; Text006_Control1470046CaptionLbl)
                    {
                    }
                    column(Text006_Control1470048Caption; Text006_Control1470048CaptionLbl)
                    {
                    }
                    column(Text006_Control1470050Caption; Text006_Control1470050CaptionLbl)
                    {
                    }
                    column(FA_History_Entry2_Entry_No_; "Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Copy("FA History Entry");
                        if ShowReport(ReportCount2) then
                            CurrReport.Break;
                    end;

                    trigger OnPreDataItem()
                    begin
                        CopyFilters("FA History Entry");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    ReportType := Text004Cap;
                    if "FA History Entry".Type = "FA History Entry".Type::Location then begin
                        if FALocation.FindLast then begin
                            Code := FALocation.Code;
                            FirstName := Text001Cap;
                            FirstName2 := FALocation.Name;
                            LastName := '';
                            LastName2 := '';
                        end;
                    end else begin
                        if Employee.FindLast then begin
                            Code := Employee."No.";
                            FirstName := Text002Cap;
                            FirstName2 := Employee."First Name";
                            LastName := Text003Cap;
                            LastName2 := Employee."Last Name";
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if "FA History Entry".Type = "FA History Entry".Type::Location then
                        FALocation.SetRange(Code, "FA History Entry"."New Value")
                    else
                        Employee.SetRange("No.", "FA History Entry"."New Value");

                    PrintDate := Format(Today, 0, 4);
                    PageNo := CurrReport.PageNo;
                    PageCaption := Text007Cap;

                    if ShowFlag then begin
                        ShowFlag := false;
                        CurrReport.Break;
                    end;
                    if "FA History Entry"."Old Value" <> '' then begin
                        ShowFlag := false;
                        PrintDate := '';
                        PageCaption := '';
                        PageNo := 0;
                    end;
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
        Employee: Record Employee;
        FALocation: Record "FA Location";
        FixedAsset: Record "Fixed Asset";
        ReportType: Text[50];
        "Code": Text[30];
        FirstName: Text[50];
        LastName: Text[50];
        FirstName2: Text[50];
        LastName2: Text[50];
        Description: Text[100];
        SerialNo: Text[50];
        PrintDate: Text[30];
        PageCaption: Text[30];
        ShowFlag: Boolean;
        ReportCount: Integer;
        ReportCount2: Integer;
        PageNo: Integer;
        Text001Cap: Label 'Name';
        Text002Cap: Label 'First Name';
        Text003Cap: Label 'Last Name';
        Text004Cap: Label 'FA Assignment';
        Text005Cap: Label 'FA Discharge';
        Text006Cap: Label '__________________________________';
        Text007Cap: Label 'Page';
        PageNoCaptionLbl: Label 'Page';
        CodeCaptionLbl: Label 'Code';
        Date_DischargedCaptionLbl: Label 'Date Discharged';
        FA_History_Entry1__FA_No__CaptionLbl: Label 'No.';
        DescriptionCaptionLbl: Label 'Description';
        SerialNoCaptionLbl: Label 'Serial No.';
        Text006CaptionLbl: Label 'Approved by';
        Text006_Control1470022CaptionLbl: Label 'Issued by';
        Text006_Control1470024CaptionLbl: Label 'Returned by';
        Code_Control1470036CaptionLbl: Label 'Code';
        Date_AssignedCaptionLbl: Label 'Date Assigned';
        FA_History_Entry2__FA_No__CaptionLbl: Label 'No.';
        SerialNo_Control1470042CaptionLbl: Label 'Serial No.';
        Description_Control1470044CaptionLbl: Label 'Description';
        Text006_Control1470046CaptionLbl: Label 'Received by';
        Text006_Control1470048CaptionLbl: Label 'Issued by';
        Text006_Control1470050CaptionLbl: Label 'Approved by';

    [Scope('OnPrem')]
    procedure ShowReport(var "Count": Integer): Boolean
    begin
        FixedAsset.Reset;
        FixedAsset.SetRange("No.", "FA History Entry"."FA No.");
        if FixedAsset.FindLast then begin
            Description := FixedAsset.Description;
            SerialNo := FixedAsset."Serial No.";
        end;
        Count := Count + 1;
        if Count > 1 then begin
            Count := 0;
            exit(true);
        end;
    end;
}

