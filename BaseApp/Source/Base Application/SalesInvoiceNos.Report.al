report 124 "Sales Invoice Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesInvoiceNos.rdlc';
    Caption = 'Sales Invoice Nos.';

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Posted Sales Invoice';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(STRSUBSTNO_Text004_SalesInvHeaderFilter_; StrSubstNo(Text004, SalesInvHeaderFilter))
            {
            }
            column(SalesInvHeaderFilter; SalesInvHeaderFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Sales_Invoice_Header_No_; "No.")
            {
            }
            column(Sales_Invoice_Nos_Caption; Sales_Invoice_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(SalesInvHeader__No__Caption; SalesInvHeader.FieldCaption("No."))
            {
            }
            column(SalesInvHeader__Source_Code_Caption; SalesInvHeader.FieldCaption("Source Code"))
            {
            }
            column(SalesInvHeader__User_ID_Caption; SalesInvHeader.FieldCaption("User ID"))
            {
            }
            column(SalesInvHeader__Bill_to_Name_Caption; SalesInvHeader.FieldCaption("Bill-to Name"))
            {
            }
            column(SalesInvHeader__Bill_to_Customer_No__Caption; SalesInvHeader.FieldCaption("Bill-to Customer No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(SalesInvHeader__Posting_Date_Caption; SalesInvHeader__Posting_Date_CaptionLbl)
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
            dataitem(SalesInvHeader; "Sales Invoice Header")
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING("No.");
                column(SalesInvHeader__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(SalesInvHeader__Source_Code_; "Source Code")
                {
                }
                column(SalesInvHeader__Bill_to_Name_; "Bill-to Name")
                {
                }
                column(SalesInvHeader__Bill_to_Customer_No__; "Bill-to Customer No.")
                {
                }
                column(SalesInvHeader__No__; "No.")
                {
                }
                column(SalesInvHeader__Posting_Date_; Format("Posting Date"))
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
                    if not FirstRecord then
                        PageGroupNo := PageGroupNo + 1;
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
                PageGroupNo := 1;
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
        SalesInvHeaderFilter := "Sales Invoice Header".GetFilters;
    end;

    var
        Text000: Label 'No number series has been used for the following entries:';
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
        Text004: Label 'Posted Sales Invoice: %1';
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        SalesInvHeaderFilter: Text;
        LastNo: Code[20];
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        PageGroupNo: Integer;
        Sales_Invoice_Nos_CaptionLbl: Label 'Sales Invoice Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        SalesInvHeader__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

