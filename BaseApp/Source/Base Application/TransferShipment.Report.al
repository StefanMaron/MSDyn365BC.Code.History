report 5704 "Transfer Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './TransferShipment.rdlc';
    Caption = 'Transfer Shipment';

    dataset
    {
        dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Transfer-from Code", "Transfer-to Code";
            RequestFilterHeading = 'Posted Transfer Shipment';
            column(No_TransShptHeader; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(CopyTextCaption; StrSubstNo(Text001, CopyText))
                    {
                    }
                    column(TransferToAddr1; TransferToAddr[1])
                    {
                    }
                    column(TransferFromAddr1; TransferFromAddr[1])
                    {
                    }
                    column(TransferToAddr2; TransferToAddr[2])
                    {
                    }
                    column(TransferFromAddr2; TransferFromAddr[2])
                    {
                    }
                    column(TransferToAddr3; TransferToAddr[3])
                    {
                    }
                    column(TransferFromAddr3; TransferFromAddr[3])
                    {
                    }
                    column(TransferToAddr4; TransferToAddr[4])
                    {
                    }
                    column(TransferFromAddr4; TransferFromAddr[4])
                    {
                    }
                    column(TransferToAddr5; TransferToAddr[5])
                    {
                    }
                    column(TransferToAddr6; TransferToAddr[6])
                    {
                    }
                    column(InTransit_TransShptHeader; "Transfer Shipment Header"."In-Transit Code")
                    {
                        IncludeCaption = true;
                    }
                    column(PostDate_TransShptHeader; Format("Transfer Shipment Header"."Posting Date", 0, 4))
                    {
                    }
                    column(No2_TransShptHeader; "Transfer Shipment Header"."No.")
                    {
                    }
                    column(TransferToAddr7; TransferToAddr[7])
                    {
                    }
                    column(TransferToAddr8; TransferToAddr[8])
                    {
                    }
                    column(TransferFromAddr5; TransferFromAddr[5])
                    {
                    }
                    column(TransferFromAddr6; TransferFromAddr[6])
                    {
                    }
                    column(ShiptDate_TransShptHeader; Format("Transfer Shipment Header"."Shipment Date"))
                    {
                    }
                    column(TransferFromAddr7; TransferFromAddr[7])
                    {
                    }
                    column(TransferFromAddr8; TransferFromAddr[8])
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(Desc_ShptMethod; ShipmentMethod.Description)
                    {
                    }
                    column(TransShptHdrNoCaption; TransShptHdrNoCaptionLbl)
                    {
                    }
                    column(TransShptShptDateCaption; TransShptShptDateCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Transfer Shipment Header";
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_DimensionLoop1; Number)
                        {
                        }
                        column(HdrDimCaption; HdrDimCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet then
                                    CurrReport.Break;
                            end else
                                if not Continue then
                                    CurrReport.Break;

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 - %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break;
                        end;
                    }
                    dataitem("Transfer Shipment Line"; "Transfer Shipment Line")
                    {
                        DataItemLink = "Document No." = FIELD("No.");
                        DataItemLinkReference = "Transfer Shipment Header";
                        DataItemTableView = SORTING("Document No.", "Line No.");
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(NoOfCopies; NoOfCopies)
                        {
                        }
                        column(ItemNo_TransShptLine; "Item No.")
                        {
                            IncludeCaption = true;
                        }
                        column(Desc_TransShptLine; Description)
                        {
                            IncludeCaption = true;
                        }
                        column(Qty_TransShptLine; Quantity)
                        {
                            IncludeCaption = true;
                        }
                        column(UOM_TransShptLine; "Unit of Measure")
                        {
                            IncludeCaption = true;
                        }
                        column(LineNo_TransShptLine; "Line No.")
                        {
                        }
                        column(DocNo_TransShptLine; "Document No.")
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            column(DimText4; DimText)
                            {
                            }
                            column(Number_DimensionLoop2; Number)
                            {
                            }
                            column(LineDimCaption; LineDimCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet then
                                        CurrReport.Break;
                                end else
                                    if not Continue then
                                        CurrReport.Break;

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 - %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break;
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimSetEntry2.SetRange("Dimension Set ID", "Dimension Set ID");
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("Item No." = '') and (Quantity = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break;
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text000;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := 1 + Abs(NoOfCopies);
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.TransferShptTransferFrom(TransferFromAddr, "Transfer Shipment Header");
                FormatAddr.TransferShptTransferTo(TransferToAddr, "Transfer Shipment Header");

                if not ShipmentMethod.Get("Shipment Method Code") then
                    ShipmentMethod.Init;
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Location;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want all dimensions assigned to the line to be shown.';
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
        PostingDateCaption = 'Posting Date';
        ShptMethodCaption = 'Shipment Method';
    }

    var
        Text000: Label 'COPY';
        Text001: Label 'Transfer Shipment %1';
        Text002: Label 'Page %1';
        ShipmentMethod: Record "Shipment Method";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        FormatAddr: Codeunit "Format Address";
        TransferFromAddr: array[8] of Text[100];
        TransferToAddr: array[8] of Text[100];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        OutputNo: Integer;
        TransShptHdrNoCaptionLbl: Label 'Shipment No.';
        TransShptShptDateCaptionLbl: Label 'Shipment Date';
        HdrDimCaptionLbl: Label 'Header Dimensions';
        LineDimCaptionLbl: Label 'Line Dimensions';
}

