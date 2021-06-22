page 5304 "Outlook Synch. Fields"
{
    AutoSplitKey = true;
    Caption = 'Outlook Synch. Fields';
    DataCaptionExpression = GetFormCaption;
    DataCaptionFields = "Synch. Entity Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Outlook Synch. Field";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Condition; Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the criteria for defining a set of specific entries to use in the synchronization process. This filter is applied to the table you specified in the Table No. field. If the Table No. field is not filled in, the program uses the value in the Master Table No. field.';

                    trigger OnAssistEdit()
                    begin
                        if IsNullGuid("Record GUID") then
                            "Record GUID" := CreateGuid;

                        Condition := CopyStr(OSynchSetupMgt.ShowOSynchFiltersForm("Record GUID", "Master Table No.", 0), 1, MaxStrLen(Condition));
                    end;
                }
                field("Table No."; "Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the supplementary table, which is used in the synchronization process when more details than those specified in the Master Table No. field are required.';
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Dynamics 365 table to synchronize. The program fills in this field when you specify a table number in the Table No. field.';
                }
                field("Table Relation"; "Table Relation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filter expression. It is used to define relation between table specified in the Table No. and Table No.';

                    trigger OnAssistEdit()
                    begin
                        if "Table No." <> 0 then begin
                            if IsNullGuid("Record GUID") then
                                "Record GUID" := CreateGuid;
                            "Table Relation" :=
                              CopyStr(OSynchSetupMgt.ShowOSynchFiltersForm("Record GUID", "Table No.", "Master Table No."), 1, MaxStrLen("Table Relation"));
                        end;
                    end;
                }
                field("Field No."; "Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the field with values that are used in the filter expression. The value in this field is appropriate if you specified the number of the table in the Table No. field. If you do not specify the table number, the program uses the number of the master table.';
                }
                field(GetFieldCaption; GetFieldCaption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    ToolTip = 'Specifies the name of the field that will be synchronized.';
                }
                field("Field Default Value"; "Field Default Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value which is inserted automatically in the field whose number is specified in the Field No. field.';
                }
                field("User-Defined"; "User-Defined")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = UserDefinedEditable;
                    ToolTip = 'Specifies that this field is defined by the user and does not belong to the standard set of fields. This option refers only to Outlook Items properties.';
                }
                field("Outlook Property"; "Outlook Property")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the Outlook item property that will be synchronized with the Dynamics 365 table field specified in the Field No. field.';
                }
                field("Search Field"; "Search Field")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SearchFieldEditable;
                    ToolTip = 'Specifies that the field will be the key property on which the search in Outlook will be based on.';
                }
                field("Read-Only Status"; "Read-Only Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the synchronization status for the mapped table field. This field has three options:';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("F&ield")
            {
                Caption = 'F&ield';
                Image = OutlookSyncFields;
                action("Option Correlations")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Option Correlations';
                    Image = OutlookSyncSubFields;
                    ToolTip = 'View option fields and the corresponding Outlook property which has the same structure (enumerations and integer). The Business Central option field can be different from the corresponding Outlook option (different element names, different elements order). In this window you set relations between option elements.';

                    trigger OnAction()
                    begin
                        ShowOOptionCorrelForm;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SearchFieldEditable := "Element No." <> 0;
        UserDefinedEditable := "Element No." = 0;
    end;

    trigger OnInit()
    begin
        UserDefinedEditable := true;
        SearchFieldEditable := true;
    end;

    var
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        [InDataSet]
        SearchFieldEditable: Boolean;
        [InDataSet]
        UserDefinedEditable: Boolean;

    procedure GetFormCaption(): Text[80]
    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
    begin
        if "Element No." = 0 then begin
            OSynchEntity.Get("Synch. Entity Code");
            exit(StrSubstNo('%1 %2', OSynchEntity.TableCaption, "Synch. Entity Code"));
        end;
        exit(StrSubstNo('%1 %2 %3', OSynchEntityElement.TableCaption, "Synch. Entity Code", "Element No."));
    end;
}

