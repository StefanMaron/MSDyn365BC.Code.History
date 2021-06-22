codeunit 890 "Query Navigation Builder"
{
    Access = internal;

    internal procedure LookupValidFilteringDataItemMetadataForSourceReference(SourceQueryRecId: BigInteger; TargetPageId: integer; var LinkingDataItemName: Text[120]): Boolean
    var
        DesignedQueryDataItem: Record "Designed Query Data Item";
        PageMetadatRec: Record "Page Metadata";
        TableMetadataRec: Record "Table Metadata";
    begin
        PageMetadatRec.SetRange(ID, TargetPageId);
        PageMetadatRec.FindFirst();

        TableMetadataRec.Init();
#pragma warning disable AA0210
        // Table Metadata has no keys defined in metadata (virtual table) but this is the PK
        TableMetadataRec.SetRange(ID, PageMetadatRec.SourceTable);
#pragma warning restore AA0210
        TableMetadataRec.FindFirst();

        DesignedQueryDataItem.FilterGroup(2);
        DesignedQueryDataItem.SetRange("Query ID", SourceQueryRecId);
        DesignedQueryDataItem.SetFilter("Source Reference", TableMetadataRec.Name);
        DesignedQueryDataItem.FilterGroup(0);
        if Page.RunModal(Page::"Query Nav. DataItem Lookup", DesignedQueryDataItem) <> ACTION::LookupOK then
            exit(false);

        LinkingDataItemName := DesignedQueryDataItem.Name;
        exit(true);
    end;

    internal procedure LookupValidTargetPageMetadataForSourceTable(SourceQueryRecId: BigInteger; var PageId: Integer; var PageName: Text; var PageSourceTableId: Integer): Boolean
    var
        DataItemsRec: Record "Designed Query Data Item";
        TableMetadataRec: Record "Table Metadata";
        PageMetadata: Record "Page Metadata";
        FilterBuilder: TextBuilder;
    begin
        DataItemsRec.SetRange("Query ID", SourceQueryRecId);
        DataItemsRec.FindSet();

        FilterBuilder.Append(DataItemsRec."Source Reference");
        while DataItemsRec.Next() > 0 do begin
            FilterBuilder.Append('|');
            FilterBuilder.Append(DataItemsRec."Source Reference");
        end;

#pragma warning disable AA0210
        // Need to resolve the actual IDs of the tables that we can use
        // because this is needed to resolve the applicable pages 
        TableMetadataRec.SetFilter(Name, FilterBuilder.ToText());
#pragma warning restore AA0210                        
        TableMetadataRec.Find('-');

        FilterBuilder.Clear();
        // Build up a filter string of the data item source references
        FilterBuilder.Append(FORMAT(TableMetadataRec.ID));
        while TableMetadataRec.Next() > 0 do begin
            FilterBuilder.Append('|');
            FilterBuilder.Append(Format(TableMetadataRec.ID));
        end;

        PageMetadata.FilterGroup(2);
        PageMetadata.SetFilter(SourceTable, FilterBuilder.ToText());
        PageMetadata.FilterGroup(0);
        if Page.RunModal(Page::"Query Nav. Page Lookup", PageMetadata) <> ACTION::LookupOK then
            exit(false);

        PageId := PageMetadata.ID;
        PageName := PageMetadata.Name;
        PageSourceTableId := PageMetadata.SourceTable;
        exit(true);
    end;
}