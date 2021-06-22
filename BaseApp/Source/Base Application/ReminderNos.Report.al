report 126 "Reminder Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './ReminderNos.rdlc';
    Caption = 'Reminder Nos.';

    dataset
    {
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Issued Reminder';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(STRSUBSTNO_Text004_ReminderHeaderFilter_; StrSubstNo(Text004, ReminderHeaderFilter))
            {
            }
            column(ReminderHeaderFilter; ReminderHeaderFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(NextPageGroupNo; NextPageGroupNo)
            {
            }
            column(Issued_Reminder_Header_No_; "No.")
            {
            }
            column(Reminder_Nos_Caption; Reminder_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(IssuedReminderHeader__No__Caption; IssuedReminderHeader.FieldCaption("No."))
            {
            }
            column(IssuedReminderHeader__Source_Code_Caption; IssuedReminderHeader.FieldCaption("Source Code"))
            {
            }
            column(IssuedReminderHeader__User_ID_Caption; IssuedReminderHeader.FieldCaption("User ID"))
            {
            }
            column(IssuedReminderHeader_NameCaption; IssuedReminderHeader.FieldCaption(Name))
            {
            }
            column(IssuedReminderHeader__Customer_No__Caption; IssuedReminderHeader.FieldCaption("Customer No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(IssuedReminderHeader__Posting_Date_Caption; IssuedReminderHeader__Posting_Date_CaptionLbl)
            {
            }
            dataitem(ErrorLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(ErrorText_Number_; ErrorText[Number])
                {
                }
                column(NewPage; NewPage)
                {
                }
                column(ErrorText_Number__Control15; ErrorText[Number])
                {
                }
                column(ErrorText_Number__Control15Caption; ErrorText_Number__Control15CaptionLbl)
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
            dataitem(IssuedReminderHeader; "Issued Reminder Header")
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING("No.");
                column(IssuedReminderHeader__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(IssuedReminderHeader__Source_Code_; "Source Code")
                {
                }
                column(IssuedReminderHeader_Name; Name)
                {
                }
                column(IssuedReminderHeader__Customer_No__; "Customer No.")
                {
                }
                column(IssuedReminderHeader__No__; "No.")
                {
                }
                column(IssuedReminderHeader__Posting_Date_; Format("Posting Date"))
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> SourceCode.Code then
                    if not SourceCode.Get("Source Code") then
                        SourceCode.Init();
                if "No. Series" <> NoSeries.Code then
                    if not NoSeries.Get("No. Series") then
                        NoSeries.Init();

                if ("No. Series" <> LastNoSeriesCode) or FirstRecord then begin
                    if "No. Series" = '' then
                        AddError(Text000)
                    else
                        AddError(
                          StrSubstNo(
                            Text001,
                            "No. Series", NoSeries.Description));
                    NewPage := true;
                end else begin
                    if LastNo <> '' then
                        if not ("No." in [LastNo, IncStr(LastNo)]) then
                            AddError(Text002)
                        else
                            if "Posting Date" < LastPostingDate then
                                AddError(Text003);
                    NewPage := false;
                end;

                LastNo := "No.";
                LastPostingDate := "Posting Date";
                LastNoSeriesCode := "No. Series";
                FirstRecord := false;

                PageGroupNo := NextPageGroupNo;
                if NewPage then
                    NextPageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;

                FirstRecord := true;
            end;
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

    trigger OnPreReport()
    begin
        ReminderHeaderFilter := "Issued Reminder Header".GetFilters;
    end;

    var
        Text000: Label 'No number series has been used for the following entries:';
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
        Text004: Label 'Issued Reminder: %1';
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        ReminderHeaderFilter: Text;
        LastNo: Code[20];
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Reminder_Nos_CaptionLbl: Label 'Reminder Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        IssuedReminderHeader__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

