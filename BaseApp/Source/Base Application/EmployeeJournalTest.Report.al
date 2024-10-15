report 17380 "Employee Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './EmployeeJournalTest.rdlc';
    Caption = 'Employee Journal - Test';

    dataset
    {
        dataitem("Employee Journal Batch"; "Employee Journal Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(Employee_Journal_Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Employee_Journal_Batch_Name; Name)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                PrintOnlyIfDetail = true;
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(Job_Journal_Batch___Journal_Template_Name_; "Employee Journal Batch"."Journal Template Name")
                {
                }
                column(Job_Journal_Batch__Name; "Employee Journal Batch".Name)
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(USERID; UserId)
                {
                }
                column(Job_Journal_Line__TABLECAPTION__________JobJnlLineFilter; "Employee Journal Line".TableCaption + ': ' + EmplJnlLineFilter)
                {
                }
                column(JobJnlLineFilter; EmplJnlLineFilter)
                {
                }
                column(Job_Journal_Batch___Journal_Template_Name_Caption; Job_Journal_Batch___Journal_Template_Name_CaptionLbl)
                {
                }
                column(Job_Journal_Batch__NameCaption; Job_Journal_Batch__NameCaptionLbl)
                {
                }
                column(Job_Journal___TestCaption; Job_Journal___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Job_Journal_Line__Document_No__Caption; "Employee Journal Line".FieldCaption("Document No."))
                {
                }
                column(Job_Journal_Line__Job_No__Caption; "Employee Journal Line".FieldCaption("Element Code"))
                {
                }
                column(Job_Journal_Line__Posting_Date_Caption; Job_Journal_Line__Posting_Date_CaptionLbl)
                {
                }
                column(Employee_Journal_Line__Employee_No__Caption; "Employee Journal Line".FieldCaption("Employee No."))
                {
                }
                column(Employee_Journal_Line__Starting_Date_Caption; "Employee Journal Line".FieldCaption("Starting Date"))
                {
                }
                column(Employee_Journal_Line__Ending_Date_Caption; "Employee Journal Line".FieldCaption("Ending Date"))
                {
                }
                column(Employee_Journal_Line__Contract_No__Caption; "Employee Journal Line".FieldCaption("Contract No."))
                {
                }
                column(Employee_Journal_Line_AmountCaption; "Employee Journal Line".FieldCaption(Amount))
                {
                }
                column(Employee_Journal_Line_DescriptionCaption; "Employee Journal Line".FieldCaption(Description))
                {
                }
                column(Integer_Number; Number)
                {
                }
                dataitem("Employee Journal Line"; "Employee Journal Line")
                {
                    DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                    DataItemLinkReference = "Employee Journal Batch";
                    DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Posting Date";
                    column(Job_Journal_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Job_Journal_Line__Job_No__; "Element Code")
                    {
                    }
                    column(Job_Journal_Line__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Employee_Journal_Line__Employee_No__; "Employee No.")
                    {
                    }
                    column(Employee_Journal_Line__Starting_Date_; "Starting Date")
                    {
                    }
                    column(Employee_Journal_Line__Ending_Date_; "Ending Date")
                    {
                    }
                    column(Employee_Journal_Line_Amount; Amount)
                    {
                    }
                    column(Employee_Journal_Line__Contract_No__; "Contract No.")
                    {
                    }
                    column(Employee_Journal_Line_Description; Description)
                    {
                    }
                    column(Employee_Journal_Line_Journal_Template_Name; "Journal Template Name")
                    {
                    }
                    column(Employee_Journal_Line_Journal_Batch_Name; "Journal Batch Name")
                    {
                    }
                    column(Employee_Journal_Line_Line_No_; "Line No.")
                    {
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(ErrorText_Number_; ErrorText[Number])
                        {
                        }
                        column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                        {
                        }
                        column(ErrorLoop_Number; Number)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if EmptyLine then
                            exit;

                        if "Element Code" = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Element Code")))
                        else
                            if not Element.Get("Element Code") then
                                AddError(StrSubstNo(Text002, "Element Code"))
                            else begin
                                //    IF Element.Blocked > Element.Blocked::" " THEN
                                //      AddError(STRSUBSTNO(Text003,Element.FIELDCAPTION(Blocked),Element.Blocked,"Element No."));
                            end;

                        if "Contract No." = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Contract No.")));

                        if "Posting Group" = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Posting Group")));

                        if "Calendar Code" = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Calendar Code")));

                        if "Payroll Calc Group" = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Payroll Calc Group")));

                        if "Document No." = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Document No.")));

                        if "Posting Date" = 0D then
                            AddError(StrSubstNo(Text001, FieldCaption("Posting Date")))
                        else begin
                            if "Posting Date" <> NormalDate("Posting Date") then
                                AddError(StrSubstNo(Text009, FieldCaption("Posting Date")));

                            if "Employee Journal Batch"."No. Series" <> '' then
                                if NoSeries."Date Order" and ("Posting Date" < LastPostingDate) then
                                    AddError(Text010);
                            LastPostingDate := "Posting Date";

                            if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                                if UserId <> '' then
                                    if UserSetup.Get(UserId) then begin
                                        AllowPostingFrom := UserSetup."Allow Posting From";
                                        AllowPostingTo := UserSetup."Allow Posting To";
                                    end;
                                if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                                    GLSetup.Get();
                                    AllowPostingFrom := GLSetup."Allow Posting From";
                                    AllowPostingTo := GLSetup."Allow Posting To";
                                end;
                                if AllowPostingTo = 0D then
                                    AllowPostingTo := 99991231D;
                            end;
                            if ("Posting Date" < AllowPostingFrom) or ("Posting Date" > AllowPostingTo) then
                                AddError(StrSubstNo(Text011, Format("Posting Date")));
                        end;

                        if "Document Date" <> 0D then
                            if "Document Date" <> NormalDate("Document Date") then
                                AddError(StrSubstNo(Text009, FieldCaption("Document Date")));

                        if "Employee Journal Batch"."No. Series" <> '' then begin
                            if LastDocNo <> '' then
                                if ("Document No." <> LastDocNo) and ("Document No." <> IncStr(LastDocNo)) then
                                    AddError(Text012);
                            LastDocNo := "Document No.";
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        EmplJnlTemplate.Get("Employee Journal Batch"."Journal Template Name");

                        if "Employee Journal Batch"."No. Series" <> '' then
                            NoSeries.Get("Employee Journal Batch"."No. Series");
                        LastPostingDate := 0D;
                        LastDocNo := '';
                    end;
                }
            }
        }
    }

    requestpage
    {
        SaveValues = true;

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

    trigger OnPreReport()
    begin
        EmplJnlLineFilter := "Employee Journal Line".GetFilters;
    end;

    var
        Text001: Label '%1 must be specified.';
        Text002: Label 'Element %1 does not exist.';
        Text009: Label '%1 must not be a closing date.';
        Text010: Label 'The lines are not listed according to posting date because they were not entered in that order.';
        Text011: Label '%1 is not within your allowed range of posting dates.';
        Text012: Label 'There is a gap in the number series.';
        UserSetup: Record "User Setup";
        GLSetup: Record "General Ledger Setup";
        Element: Record "Payroll Element";
        EmplJnlTemplate: Record "Employee Journal Template";
        NoSeries: Record "No. Series";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        EmplJnlLineFilter: Text[250];
        LastPostingDate: Date;
        LastDocNo: Code[20];
        Job_Journal_Batch___Journal_Template_Name_CaptionLbl: Label 'Journal Template';
        Job_Journal_Batch__NameCaptionLbl: Label 'Journal Batch';
        Job_Journal___TestCaptionLbl: Label 'Employee Journal - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Job_Journal_Line__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number_CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

