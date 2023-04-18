report 6529 "Item Tracking Navigate"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryMgt/ItemTracking/ItemTrackingNavigate.rdlc';
    Caption = 'Item Tracking Navigate';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Head3View; ItemFilters.GetFilter("Serial No. Filter") <> '')
            {
            }
            column(Head4View; ItemFilters.GetFilter("Lot No. Filter") <> '')
            {
            }
            column(Head5View; ItemFilters.GetFilter("No.") <> '')
            {
            }
            column(Head6View; ItemFilters.GetFilter("Variant Filter") <> '')
            {
            }
            column(FormatedSerialNoFilter; Text001 + Format(ItemFilters.GetFilter("Serial No. Filter")))
            {
            }
            column(FormatedLotNoFilter; Text002 + Format(ItemFilters.GetFilter("Lot No. Filter")))
            {
            }
            column(FormatedtemNoFilter; Text003 + Format(ItemFilters.GetFilter("No.")))
            {
            }
            column(FormatedVariantFilter; Text004 + Format(ItemFilters.GetFilter("Variant Filter")))
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
                        if TempRecordBuffer.Next() = 0 then
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
                    if TempDocEntry.Next() = 0 then
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
        TempDocEntry: Record "Document Entry" temporary;
        TempRecordBuffer: Record "Record Buffer" temporary;
        ItemFilters: Record Item;
        PrintOnlyOnePerPage: Boolean;
        RecordCounter: Integer;

        Text001: Label 'Serial No. : ';
        Text002: Label 'Lot No. : ';
        Text003: Label 'Item No. : ';
        Text004: Label 'Variant Code. : ';
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
            until NewDocEntry.Next() = 0;
        NewDocEntry := TempDocumentEntry;
    end;

    procedure TransferRecordBuffer(var NewRecordBuffer: Record "Record Buffer")
    begin
        NewRecordBuffer.Reset();
        if NewRecordBuffer.Find('-') then
            repeat
                TempRecordBuffer := NewRecordBuffer;
                TempRecordBuffer.Insert();
            until NewRecordBuffer.Next() = 0;
    end;

    [Obsolete('Replaced by SetItemFilters().', '18.0')]
    procedure TransferFilters(NewSerialNoFilter: Text; NewLotNoFilter: Text; NewItemNoFilter: Text; NewVariantFilter: Text)
    begin
        ItemFilters.SetFilter("Serial No. Filter", NewSerialNoFilter);
        ItemFilters.SetFilter("Lot No. Filter", NewLotNoFilter);
        ItemFilters.SetFilter("No.", NewItemNoFilter);
        ItemFilters.SetFilter("Variant Filter", NewVariantFilter);
    end;

    procedure SetTrackingFilters(var NewItemFilters: Record Item)
    begin
        ItemFilters.CopyFilters(NewItemFilters);
    end;
}

