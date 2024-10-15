page 20286 "Tax Table Relation Dialog"
{
    Caption = 'Tax Table Relation Dialog';
    PageType = StandardDialog;
    DataCaptionExpression = '';
    SourceTable = "Tax Table Relation";

    layout
    {
        area(Content)
        {
            group(Group5)
            {
                Caption = 'Lookup Table';
                field("Lookup Table"; LookupTableName)
                {
                    Caption = 'Table Name';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table name for table relation.';

                    trigger OnValidate();
                    var
                        xTableID: Integer;
                    begin
                        xTableID := "Source ID";
                        UseCase.Get("Case ID");
                        TaxTypeObjectHelper.SearchTaxTypeTable(
                            "Source ID",
                            LookupTableName,
                            UseCase."Tax Type",
                            false);
                        HandleTableChange(xTableID)

                    end;

                    trigger OnLookup(var Text: Text): Boolean;
                    var
                        xTableID: Integer;
                    begin
                        xTableID := "Source ID";
                        UseCase.Get("Case ID");
                        TaxTypeObjectHelper.OpenTaxTypeTableLookup(
                            "Source ID",
                            LookupTableName,
                            LookupTableName,
                            UseCase."Tax Type");

                        HandleTableChange(xTableID);
                    end;
                }

                field("Lookup Table Filters"; LookupTableFilters)
                {
                    Caption = 'Table Filters';
                    ToolTip = 'Specifies the table Filter for table Relation.';
                    Editable = false;
                    Width = 1024;
                    ApplicationArea = Basic, Suite;

                    trigger OnAssistEdit();
                    begin
                        if "Source ID" = 0 then
                            Exit;

                        if IsNullGuid("Table Filter ID") then
                            "Table Filter ID" := LookupEntityMgmt.CreateTableFilters(
                                "Case ID",
                                EmptyGuid,
                                "Source ID");

                        LookupDialogMgmt.OpenTableFilterDialog("Case ID", EmptyGuid, "Table Filter ID");

                        UpdatePageControls();
                    end;
                }
            }
        }
    }

    procedure SetCurrentRecord(var TaxTableRelation2: Record "Tax Table Relation");
    begin
        TaxTableRelation := TaxTableRelation2;
        TestRecord();

        FilterGroup := 2;
        SetRange("Case ID", TaxTableRelation."Case ID");
        SetRange(ID, TaxTableRelation.ID);
        FilterGroup := 0;
    end;

    local procedure TestRecord();
    begin
        TaxTableRelation.TestField("Case ID");
        TaxTableRelation.TestField(ID);
    end;

    local procedure HandleTableChange(xTableID: Integer);
    begin
        if xTableID = "Source ID" then
            Exit;

        LookupTableFieldName := '';
        LookupTableFilters := '';

        if not IsNullGuid("Table Filter ID") then
            LookupEntityMgmt.DeleteTableFilters("Case ID", EmptyGuid, "Table Filter ID");
    end;

    local procedure UpdatePageControls();
    begin
        LookupTableName := AppObjectHelper.GetObjectName(ObjectType::Table, "Source ID");

        if not IsNullGuid("Table Filter ID") then
            LookupTableFilters := LookupSerialization.TableFilterToString("Case ID", EmptyGuid, Rec."Table Filter ID")
        else
            LookupTableFilters := '';
    end;

    procedure SetDatatype(ExpectedDatatype2: Integer);
    begin
        ExpectedDatatype := ExpectedDatatype2;
        ApplyDatatypeFilter := true;
    end;

    trigger OnAfterGetCurrRecord();
    begin
        UpdatePageControls();
    end;

    var
        TaxTableRelation: Record "Tax Table Relation";
        UseCase: Record "Tax Use Case";
        LookupEntityMgmt: Codeunit "Lookup Entity Mgmt.";
        LookupSerialization: Codeunit "Lookup Serialization";
        TaxTypeObjectHelper: Codeunit "Tax Type Object Helper";
        AppObjectHelper: Codeunit "App Object Helper";
        LookupDialogMgmt: Codeunit "Lookup Dialog Mgmt.";
        EmptyGuid: Guid;
        LookupTableName: Text[30];
        LookupTableFieldName: Text[30];
        LookupTableFilters: Text;
        ExpectedDatatype: Integer;
        ApplyDatatypeFilter: Boolean;
}