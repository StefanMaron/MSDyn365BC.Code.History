page 989 "Query Navigation Builder"
{
    PageType = StandardDialog;
    Extensible = false;
    PopulateAllFields = true;
    ShowFilter = false;
    RefreshOnActivate = true;
    Caption = 'Query Navigation';

    layout
    {
        area(Content)
        {
            group(OverviewGroup)
            {
                ShowCaption = false;

                field(Name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'The name for the Navigation item being created';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if Name = '' then
                            Error(NameRequiredErr);
                    end;
                }

                field(TargetPage; TargetPageName)
                {
                    ApplicationArea = All;
                    Caption = 'Target Page';
                    ToolTip = 'Specifies the page that will be navigated to when the Navigation is selected.';
                    Editable = false;
                    AssistEdit = true;
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    var
                        QueryNavigationBuilder: Codeunit "Query Navigation Builder";
                        TempId: Integer;
                        TempSourceTable: Integer;
                        TempName: Text;
                    begin
                        if QueryNavigationBuilder.LookupValidTargetPageMetadataForSourceTable(SourceQueryRecId, tempId, TempName, TempSourceTable) then begin
                            TargetPageId := TempId;
                            TargetPageName := TempName;
                            TargetPageSourceTable := TempSourceTable;
                            SetOrClearLinkingDataItem();
                        end;
                    end;
                }

                field(FilterToRecord; FilterToRecord)
                {
                    ApplicationArea = All;
                    Enabled = TargetPageName <> '';
                    Caption = 'Filter To Record ';
                    ToolTip = 'Choose if the Navigation should filter the opened page based on the record that was selected in the query.';

                    trigger OnValidate()
                    begin
                        SetOrClearLinkingDataItem();
                    end;
                }

                group(LinkGroup)
                {
                    ShowCaption = false;
                    Visible = FilterToRecord;
                    field(LinkingDataItemName; LinkingDataItemName)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Caption = 'Linking Data Item';
                        ToolTip = 'Specifies what Data Item on the query should be used to generate filters for the target page.';
                        AssistEdit = true;

                        trigger OnAssistEdit()
                        var
                            QueryNavigationBuilder: Codeunit "Query Navigation Builder";
                            TempDataItemName: Text[120];
                        begin
                            if QueryNavigationBuilder.LookupValidFilteringDataItemMetadataForSourceReference(SourceQueryRecId, TargetPageId, TempDataItemName) then
                                LinkingDataItemName := TempDataItemName;

                            CurrPage.Update(true);
                        end;
                    }
                }
            }
        }
    }

    local procedure SetOrClearLinkingDataItem()
    var
        DesignedQueryDataItemRec: Record "Designed Query Data Item";
        TableMetadataRec: Record "Table Metadata";
        LinkingName: Text[120];
    begin
        if not FilterToRecord then
            LinkingName := '' // Clear name when we switch filter to record 'off'
        else begin
            TableMetadataRec.Init();
            TableMetadataRec.SetRange(ID, TargetPageSourceTable);
            TableMetadataRec.FindFirst();

            DesignedQueryDataItemRec.SetRange("Query ID", SourceQueryRecId);
            DesignedQueryDataItemRec.SetRange("Source Reference", TableMetadataRec.Name);
            DesignedQueryDataItemRec.FindSet();
            if DesignedQueryDataItemRec.Count() = 1 then
                LinkingName := DesignedQueryDataItemRec.Name;
        end;

        LinkingDataItemName := LinkingName;
        CurrPage.Update(true);
    end;

    trigger OnOpenPage()
    var
        ValidationResult: Record "Query Navigation Validation";
        QueryNavigationValidation: Codeunit "Query Navigation Validation";
        SmartListManagement: Codeunit "SmartList Mgmt";
    begin
        if not SmartListManagement.DoesUserHaveManagementAccess(UserSecurityId()) then
            Error(UserDoesNotHaveManagementAccessErr);

        // Display the invalid reason if we are editing an existing record and it is not valid.
        // This means that the user won't have to prematurely select 'ok' to determine what is wrong.
        if (Id <> 0) and (not QueryNavigationValidation.ValidateNavigation(SourceQueryObjectId, TargetPageId, LinkingDataItemName, ValidationResult)) then
            Message(ValidationResult.Reason);
    end;

    internal procedure OpenForCreatingNewNavigation(QueryObjectId: Integer)
    begin
        InitializeCommon(QueryObjectId);
        Id := 0; // Set Auto-Increment id value to zero to avoid initial collisions when inserting a new item
        CurrPage.Run();
    end;

    internal procedure OpenForEditingExistingNavigation(QueryNavigationRec: Record "Query Navigation")
    var
        PageMetadata: Record "Page Metadata";
    begin
        InitializeCommon(QueryNavigationRec."Source Query Object Id");

        Id := QueryNavigationRec.Id;
        Name := QueryNavigationRec.Name;

        // Calculate the various target page information upfront
        TargetPageId := QueryNavigationRec."Target Page Id";
        PageMetadata.SetRange(ID, TargetPageId);
        if PageMetadata.FindFirst() then begin
            TargetPageName := PageMetadata.Name;
            TargetPageSourceTable := PageMetadata.SourceTable;
        end;

        FilterToRecord := QueryNavigationRec."Linking Data Item Name" <> '';
        LinkingDataItemName := QueryNavigationRec."Linking Data Item Name";

        IsDefault := QueryNavigationRec.Default;

        CurrPage.Run();
    end;

    local procedure InitializeCommon(QueryObjectId: Integer)
    var
        QueryManagementRec: Record "Designed Query Management";
    begin
        SourceQueryObjectId := QueryObjectId;

        // Find the source query object record id
        // it is needed for lookups the related designed query tables
        QueryManagementRec.SetRange("Object ID", QueryObjectId);
        if not QueryManagementRec.FindFirst() then
            Error(CouldNotFindQueryErr, QueryObjectId);

        SourceQueryRecId := QueryManagementRec."Query ID";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        OtherQueryNavigationRec: Record "Query Navigation";
        QueryNavigationRec: Record "Query Navigation";
        ValidationResult: Record "Query Navigation Validation";
        QueryNavigationValidation: Codeunit "Query Navigation Validation";
    begin
        if CloseAction <> CloseAction::OK then
            exit(true);

        if Name = '' then
            Error(NameRequiredErr);

        if TargetPageId = 0 then
            Error(TargetPageRequiredErr);

        OtherQueryNavigationRec.SetRange("Source Query Object Id", SourceQueryObjectId);
        IsDefault := IsDefault or OtherQueryNavigationRec.IsEmpty();

        QueryNavigationRec.Id := Id;
        QueryNavigationRec.Name := Name;
        QueryNavigationRec."Source Query Object Id" := SourceQueryObjectId;
        QueryNavigationRec."Target Page Id" := TargetPageId;
        QueryNavigationRec."Linking Data Item Name" := LinkingDataItemName;
        QueryNavigationRec.Default := IsDefault;

        if not QueryNavigationValidation.ValidateNavigation(QueryNavigationRec, ValidationResult) then
            Error(ValidationResult.Reason);

        if QueryNavigationRec.Id <> 0 then
            QueryNavigationRec.Modify()
        else
            QueryNavigationRec.Insert();

        exit(true);
    end;

    var
        UserDoesNotHaveManagementAccessErr: Label 'You do not have permission to manage SmartLists. Contact your system administrator.';
        CouldNotFindQueryErr: Label 'Could not find Query %1', Comment = '%1 = id of a query object';
        NameRequiredErr: Label 'Name is required';
        TargetPageRequiredErr: Label 'Target Page is required';
        SourceQueryObjectId: Integer;
        SourceQueryRecId: BigInteger;
        Id: BigInteger;
        Name: Text[250];
        TargetPageId: Integer;
        TargetPageName: Text;
        TargetPageSourceTable: Integer;
        FilterToRecord: Boolean;
        LinkingDataItemName: Text[250];
        IsDefault: Boolean;
}