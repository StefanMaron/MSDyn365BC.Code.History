report 6529 "Item Tracking Navigate"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ItemTrackingNavigate.rdlc';
    Caption = 'Item Tracking Navigate';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(Head3View; SerialNoFilter <> '')
            {
            }
            column(Head4View; LotNoFilter <> '')
            {
            }
            column(Head5View; ItemNoFilter <> '')
            {
            }
            column(Head6View; VariantFilter <> '')
            {
            }
            column(FormatedSerialNoFilter; Text001 + Format(SerialNoFilter))
            {
            }
            column(FormatedLotNoFilter; Text002 + Format(LotNoFilter))
            {
            }
            column(FormatedtemNoFilter; Text003 + Format(ItemNoFilter))
            {
            }
            column(FormatedVariantFilter; Text004 + Format(VariantFilter))
            {
            }
            column(ItemTrackingNavigateCaption; ItemTrackingNavigateCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(NavigateFiltersCaption; NavigateFiltersCaptionLbl)
            {
            }
            dataitem(RecordBuffer; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(TempDocEntryNoOfRecords; TempDocEntry."No. of Records")
                {
                }
                column(TempDocEntryTableName; TempDocEntry."Table Name")
                {
                }
                column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                {
                }
                column(RecordCounter; RecordCounter)
                {
                }
                column(TempRecordBufferPrimaryKey; TempRecordBuffer."Primary Key")
                {
                }
                column(TempRecordBufferSerialNo; TempRecordBuffer."Serial No.")
                {
                }
                column(TempRecordBufferLotNo; TempRecordBuffer."Lot No.")
                {
                }
                column(TempDocEntryNoofRecordsCaption; TempDocEntryNoofRecordsCaptionLbl)
                {
                }
                column(TempDocEntryTableNameCaption; TempDocEntryTableNameCaptionLbl)
                {
                }
                column(TempRecordBufferSerialNoCaption; TempRecordBufferSerialNoCaptionLbl)
                {
                }
                column(TempRecordBufferLotNoCaption; TempRecordBufferLotNoCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not TempRecordBuffer.Find('-') then
                            CurrReport.Break();
                    end else
                        if TempRecordBuffer.Next = 0 then
                            CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    TempRecordBuffer.SetCurrentKey("Table No.", "Search Record ID");
                    TempRecordBuffer.SetRange("Table No.", TempDocEntry."Table ID");
                    RecordCounter := RecordCounter + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempDocEntry.Find('-') then
                        CurrReport.Break();
                end else
                    if TempDocEntry.Next = 0 then
                        CurrReport.Break();
            end;

            trigger OnPreDataItem()
            begin
                RecordCounter := 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'New Page per Table';
                        ToolTip = 'Specifies if you want each different table where the serial or lot number is used to be listed on a different page.';
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
        Text001: Label 'Serial No. : ';
        Text002: Label 'Lot No. : ';
        TempDocEntry: Record "Document Entry" temporary;
        TempRecordBuffer: Record "Record Buffer" temporary;
        SerialNoFilter: Text;
        LotNoFilter: Text;
        ItemNoFilter: Text;
        VariantFilter: Text;
        Text003: Label 'Item No. : ';
        Text004: Label 'Variant Code. : ';
        PrintOnlyOnePerPage: Boolean;
        RecordCounter: Integer;
        ItemTrackingNavigateCaptionLbl: Label 'Item Tracking Navigate';
        CurrReportPageNoCaptionLbl: Label 'Page';
        NavigateFiltersCaptionLbl: Label 'Navigate Filters';
        TempDocEntryNoofRecordsCaptionLbl: Label 'No. of Records';
        TempDocEntryTableNameCaptionLbl: Label 'Table Name';
        TempRecordBufferSerialNoCaptionLbl: Label 'Serial No.';
        TempRecordBufferLotNoCaptionLbl: Label 'Lot No.';

    procedure TransferDocEntries(var NewDocEntry: Record "Document Entry")
    var
        TempDocumentEntry: Record "Document Entry";
    begin
        TempDocumentEntry := NewDocEntry;
        NewDocEntry.Reset();
        if NewDocEntry.Find('-') then
            repeat
                TempDocEntry := NewDocEntry;
                TempDocEntry.Insert();
            until NewDocEntry.Next = 0;
        NewDocEntry := TempDocumentEntry;
    end;

    procedure TransferRecordBuffer(var NewRecordBuffer: Record "Record Buffer")
    begin
        NewRecordBuffer.Reset();
        if NewRecordBuffer.Find('-') then
            repeat
                TempRecordBuffer := NewRecordBuffer;
                TempRecordBuffer.Insert();
            until NewRecordBuffer.Next = 0;
    end;

    procedure TransferFilters(NewSerialNoFilter: Text; NewLotNoFilter: Text; NewItemNoFilter: Text; NewVariantFilter: Text)
    begin
        SerialNoFilter := NewSerialNoFilter;
        LotNoFilter := NewLotNoFilter;
        ItemNoFilter := NewItemNoFilter;
        VariantFilter := NewVariantFilter;
    end;
}

