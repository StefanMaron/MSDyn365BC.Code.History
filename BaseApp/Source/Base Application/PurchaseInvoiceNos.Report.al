report 324 "Purchase Invoice Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './PurchaseInvoiceNos.rdlc';
    Caption = 'Purchase Invoice Nos.';

    dataset
    {
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Posted Purchase Invoice';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(STRSUBSTNO_Text004_PurchInvHeaderFilter_; StrSubstNo(Text004, PurchInvHeaderFilter))
            {
            }
            column(PurchInvHeaderFilter; PurchInvHeaderFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Purch__Inv__Header_No_; "No.")
            {
            }
            column(Purchase_Invoice_Nos_Caption; Purchase_Invoice_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(PurchInvHeader__No__Caption; PurchInvHeader.FieldCaption("No."))
            {
            }
            column(PurchInvHeader__Source_Code_Caption; PurchInvHeader.FieldCaption("Source Code"))
            {
            }
            column(PurchInvHeader__User_ID_Caption; PurchInvHeader.FieldCaption("User ID"))
            {
            }
            column(PurchInvHeader__Pay_to_Name_Caption; PurchInvHeader.FieldCaption("Pay-to Name"))
            {
            }
            column(PurchInvHeader__Pay_to_Vendor_No__Caption; PurchInvHeader.FieldCaption("Pay-to Vendor No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(PurchInvHeader__Posting_Date_Caption; PurchInvHeader__Posting_Date_CaptionLbl)
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
            dataitem(PurchInvHeader; "Purch. Inv. Header")
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING("No.");
                column(PurchInvHeader__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(PurchInvHeader__Source_Code_; "Source Code")
                {
                }
                column(PurchInvHeader__Pay_to_Name_; "Pay-to Name")
                {
                }
                column(PurchInvHeader__Pay_to_Vendor_No__; "Pay-to Vendor No.")
                {
                }
                column(PurchInvHeader__No__; "No.")
                {
                }
                column(PurchInvHeader__Posting_Date_; Format("Posting Date"))
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
                PageGroupNo := 1;
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
        PurchInvHeaderFilter := "Purch. Inv. Header".GetFilters;
    end;

    var
        Text000: Label 'No number series has been used for the following entries:';
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
        Text004: Label 'Posted Purchase Invoice: %1';
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        PurchInvHeaderFilter: Text;
        LastNo: Code[20];
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        PageGroupNo: Integer;
        Purchase_Invoice_Nos_CaptionLbl: Label 'Purchase Invoice Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        PurchInvHeader__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

