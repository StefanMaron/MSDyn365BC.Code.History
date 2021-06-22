page 5336 "CRM Coupling Record"
{
    Caption = 'Common Data Service Coupling Record';
    PageType = StandardDialog;
    SourceTable = "Coupling Record Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control11)
            {
                ShowCaption = false;
                grid(Coupling)
                {
                    Caption = 'Coupling';
                    GridLayout = Columns;
                    group("Business Central")
                    {
                        Caption = 'Business Central';
                        field(NAVName; "NAV Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Business Central Name';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the name of the record in Business Central to couple to an existing Common Data Service record.';
                        }
                        group(Control13)
                        {
                            ShowCaption = false;
                            field(SyncActionControl; "Sync Action")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Synchronize After Coupling';
                                Enabled = NOT "Create New";
                                OptionCaption = 'No,Yes - Use the Business Central data,Yes - Use the Common Data Service data';
                                ToolTip = 'Specifies whether to synchronize the data in the record in Business Central and the record in Common Data Service.';
                            }
                        }
                    }
                    group("Dynamics 365 Sales")
                    {
                        Caption = 'Common Data Service';
                        field(CRMName; "CRM Name")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Common Data Service Name';
                            Enabled = NOT "Create New";
                            ShowCaption = false;
                            ToolTip = 'Specifies the name of the record in Common Data Service that is coupled to the record in Business Central.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookUpCRMName;
                                RefreshFields;
                            end;

                            trigger OnValidate()
                            begin
                                RefreshFields
                            end;
                        }
                        group(Control15)
                        {
                            ShowCaption = false;
                            field(CreateNewControl; "Create New")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Create New';
                                Enabled = EnableCreateNew;
                                ToolTip = 'Specifies if a new record in Common Data Service is automatically created and coupled to the related record in Business Central.';
                            }
                        }
                    }
                }
            }
            part(CoupledFields; "CRM Coupled Fields")
            {
                ApplicationArea = Suite;
                Caption = 'Fields';
                ShowFilter = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RefreshFields
    end;

    var
        EnableCreateNew: Boolean;

    procedure GetCRMId(): Guid
    begin
        exit("CRM ID");
    end;

    local procedure RefreshFields()
    begin
        CurrPage.CoupledFields.PAGE.SetSourceRecord(Rec);
    end;

    procedure SetSourceRecordID(RecordID: RecordID)
    begin
        Initialize(RecordID);
        Insert;
        EnableCreateNew := "Sync Action" = "Sync Action"::"To Integration Table";
    end;
}

