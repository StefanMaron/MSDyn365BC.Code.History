report 127 "Finance Charge Memo Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './FinanceChargeMemoNos.rdlc';
    Caption = 'Finance Charge Memo Nos.';

    dataset
    {
        dataitem("Issued Fin. Charge Memo Header"; "Issued Fin. Charge Memo Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Issued Finance Charge Memo';
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(STRSUBSTNO_Text004_FinChrgMemoHeaderFilter_; StrSubstNo(Text004, FinChrgMemoHeaderFilter))
            {
            }
            column(FinChrgMemoHeaderFilter; FinChrgMemoHeaderFilter)
            {
            }
            column(Finance_Charge_Memo_Nos_Caption; Finance_Charge_Memo_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(IssuedFinChrgMemoHeader__No__Caption; IssuedFinChrgMemoHeader.FieldCaption("No."))
            {
            }
            column(IssuedFinChrgMemoHeader__Source_Code_Caption; IssuedFinChrgMemoHeader.FieldCaption("Source Code"))
            {
            }
            column(IssuedFinChrgMemoHeader__User_ID_Caption; IssuedFinChrgMemoHeader.FieldCaption("User ID"))
            {
            }
            column(IssuedFinChrgMemoHeader_NameCaption; IssuedFinChrgMemoHeader.FieldCaption(Name))
            {
            }
            column(IssuedFinChrgMemoHeader__Customer_No__Caption; IssuedFinChrgMemoHeader.FieldCaption("Customer No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(IssuedFinChrgMemoHeader__Posting_Date_Caption; IssuedFinChrgMemoHeader__Posting_Date_CaptionLbl)
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
            dataitem(IssuedFinChrgMemoHeader; "Issued Fin. Charge Memo Header")
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING("No.");
                column(IssuedFinChrgMemoHeader__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(IssuedFinChrgMemoHeader__Source_Code_; "Source Code")
                {
                }
                column(IssuedFinChrgMemoHeader_Name; Name)
                {
                }
                column(IssuedFinChrgMemoHeader__Customer_No__; "Customer No.")
                {
                }
                column(IssuedFinChrgMemoHeader__No__; "No.")
                {
                }
                column(IssuedFinChrgMemoHeader__Posting_Date_; Format("Posting Date"))
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
            end;

            trigger OnPreDataItem()
            begin
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
        FinChrgMemoHeaderFilter := "Issued Fin. Charge Memo Header".GetFilters;
    end;

    var
        Text000: Label 'No number series has been used for the following entries:';
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
        Text004: Label 'Issued Finance Charge Memo: %1';
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        FinChrgMemoHeaderFilter: Text;
        LastNo: Code[20];
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        Finance_Charge_Memo_Nos_CaptionLbl: Label 'Finance Charge Memo Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SourceCode_DescriptionCaptionLbl: Label 'Description';
        IssuedFinChrgMemoHeader__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

