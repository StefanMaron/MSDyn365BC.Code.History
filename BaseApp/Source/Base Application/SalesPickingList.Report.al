report 11512 "Sales Picking List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesPickingList.rdlc';
    Caption = 'Picking List';
    Permissions =;

    dataset
    {
        dataitem(Head; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            column(No_Head; "No.")
            {
            }
            column(SignatureCaption; SignatureCaptionLbl)
            {
            }
            column(FooterLabel1; FooterLabel[1])
            {
            }
            column(FooterTxt1; FooterTxt[1])
            {
            }
            column(FooterTxt2; FooterTxt[2])
            {
            }
            column(FooterLabel2; FooterLabel[2])
            {
            }
            column(FooterTxt3; FooterTxt[3])
            {
            }
            column(FooterLabel3; FooterLabel[3])
            {
            }
            column(TotalQtyCaption; TotalQtyCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(Adr1; Adr[1])
                    {
                    }
                    column(Adr2; Adr[2])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(CompanyAdr1; CompanyAdr[1])
                    {
                    }
                    column(CompanyAdr2; CompanyAdr[2])
                    {
                    }
                    column(Adr3; Adr[3])
                    {
                    }
                    column(CompanyAdr3; CompanyAdr[3])
                    {
                    }
                    column(Adr4; Adr[4])
                    {
                    }
                    column(CompanyAdr4; CompanyAdr[4])
                    {
                    }
                    column(Adr5; Adr[5])
                    {
                    }
                    column(CompanyAdr5; CompanyAdr[5])
                    {
                    }
                    column(Adr6; Adr[6])
                    {
                    }
                    column(CompanyAdr6; CompanyAdr[6])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(Adr7; Adr[7])
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(Adr8; Adr[8])
                    {
                    }
                    column(CompanyInfoVATRegistrationNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(HeadBilltoCustomerNo; Head."Bill-to Customer No.")
                    {
                    }
                    column(TitleTxtHeadNo; TitleTxt + ' ' + Head."No.")
                    {
                    }
                    column(HeadDocumentDate; Head."Document Date")
                    {
                    }
                    column(HeaderTxt1; HeaderTxt[1])
                    {
                    }
                    column(HeaderLabel1; HeaderLabel[1])
                    {
                    }
                    column(HeaderTxt2; HeaderTxt[2])
                    {
                    }
                    column(HeaderLabel2; HeaderLabel[2])
                    {
                    }
                    column(HeaderTxt3; HeaderTxt[3])
                    {
                    }
                    column(HeaderLabel3; HeaderLabel[3])
                    {
                    }
                    column(HeaderLabel4; HeaderLabel[4])
                    {
                    }
                    column(HeaderTxt4; HeaderTxt[4])
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(TelephoneCaption; TelephoneCaptionLbl)
                    {
                    }
                    column(FaxCaption; FaxCaptionLbl)
                    {
                    }
                    column(VATNumberCaption; VATNumberCaptionLbl)
                    {
                    }
                    column(DateCaption; DateCaptionLbl)
                    {
                    }
                    column(CustomerNoCaption; CustomerNoCaptionLbl)
                    {
                    }
                    column(NumberCaption; NumberCaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(LocationCaption; LocationCaptionLbl)
                    {
                    }
                    column(BinCaption; BinCaptionLbl)
                    {
                    }
                    column(UnitCaption; UnitCaptionLbl)
                    {
                    }
                    column(QtyCaption; QtyCaptionLbl)
                    {
                    }
                    column(PreparedQtyCaption; PreparedQtyCaptionLbl)
                    {
                    }
                    column(SerialNoCaption; SerialNoCaptionLbl)
                    {
                    }
                    dataitem(Line; "Sales Line")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                        DataItemLinkReference = Head;
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");
                        column(No_Line; "No.")
                        {
                        }
                        column(Description; Description)
                        {
                        }
                        column(LocationCode_Line; "Location Code")
                        {
                        }
                        column(BinCode_Line; "Bin Code")
                        {
                        }
                        column(UnitofMeasure_Line; "Unit of Measure")
                        {
                        }
                        column(QtytoShip_Line; "Qty. to Ship")
                        {
                        }
                        column(EmptyString; '')
                        {
                        }
                        column(TypeTypeTitle; Type < Type::Title)
                        {
                        }
                        column(DocumentNo_Line; "Document No.")
                        {
                        }
                    }
                    dataitem(TotalElement; "Integer")
                    {
                        DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = CONST(1));
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyTxt := ML_Copy;
                        OutputNo := OutputNo + 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    CopyTxt := '';
                    CopiesToPrint := ReqCopies + Customer."Invoice Copies" + 1;

                    SetRange(Number, 1, CopiesToPrint);  // Integer table
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PrepareHeader;
                PrepareFooter;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get;
                FormatAdr.Company(CompanyAdr, CompanyInfo);
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
                    field(ReqCopies; ReqCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        MinValue = 0;
                        ToolTip = 'Specifies how many copies of the document to print.';
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
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        FormatAdr: Codeunit "Format Address";
        Adr: array[8] of Text[100];
        CompanyAdr: array[8] of Text[100];
        ReqCopies: Integer;
        CopiesToPrint: Integer;
        ML_PickList: Label 'Picking List for Order';
        ML_Page: Label 'Page';
        TitleTxt: Text[50];
        CopyTxt: Text[30];
        HeaderLabel: array[20] of Text[30];
        HeaderTxt: array[20] of Text;
        FooterLabel: array[20] of Text[30];
        FooterTxt: array[20] of Text;
        ML_Copy: Label 'Copy';
        OutputNo: Integer;
        TelephoneCaptionLbl: Label 'Telephone';
        FaxCaptionLbl: Label 'Fax';
        VATNumberCaptionLbl: Label 'VAT Number';
        DateCaptionLbl: Label 'Date';
        CustomerNoCaptionLbl: Label 'Customer No.';
        NumberCaptionLbl: Label 'Number';
        DescriptionCaptionLbl: Label 'Description';
        LocationCaptionLbl: Label 'Location';
        BinCaptionLbl: Label 'Bin';
        UnitCaptionLbl: Label 'Unit';
        QtyCaptionLbl: Label 'Qty.';
        PreparedQtyCaptionLbl: Label 'Prepared Qty.';
        SerialNoCaptionLbl: Label 'Serial No.';
        TotalQtyCaptionLbl: Label 'Total Qty';
        SignatureCaptionLbl: Label 'Signature';

    [Scope('OnPrem')]
    procedure PrepareHeader()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        TitleTxt := ML_PickList;
        FormatAdr.SalesHeaderSellTo(Adr, Head);
        RecRef.GetTable(Head);
        CHReportManagement.PrepareHeader(RecRef, REPORT::"Sales Picking List", HeaderLabel, HeaderTxt);
    end;

    [Scope('OnPrem')]
    procedure PrepareFooter()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Head);
        CHReportManagement.PrepareFooter(RecRef, REPORT::"Sales Picking List", FooterLabel, FooterTxt);
    end;
}

