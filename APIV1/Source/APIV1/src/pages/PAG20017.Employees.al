page 20017 "APIV1 - Employees"
{
    APIVersion = 'v1.0';
    Caption = 'employees', Locked = true;
    DelayedInsert = true;
    EntityName = 'employee';
    EntitySetName = 'employees';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = 5200;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(displayName; DisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    Editable = false;
                }
                field(givenName; "First Name")
                {
                    ApplicationArea = All;
                    Caption = 'givenName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("First Name"));
                    end;
                }
                field(middleName; "Middle Name")
                {
                    ApplicationArea = All;
                    Caption = 'middleName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Middle Name"));
                    end;
                }
                field(surname; "Last Name")
                {
                    ApplicationArea = All;
                    Caption = 'surname', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Last Name"));
                    end;
                }
                field(jobTitle; "Job Title")
                {
                    ApplicationArea = All;
                    Caption = 'jobTitle', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Job Title"));
                    end;
                }
                field(address; PostalAddressJSON)
                {
                    ApplicationArea = All;
                    Caption = 'address', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the address for the employee.';
                }
                field(phoneNumber; "Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'phoneNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Phone No."));
                    end;
                }
                field(mobilePhone; "Mobile Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'mobilePhone', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Mobile Phone No."));
                    end;
                }
                field(email; "Company E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Company E-Mail"));
                    end;
                }
                field(personalEmail; "E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'personalEmail', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("E-Mail"));
                    end;
                }
                field(employmentDate; "Employment Date")
                {
                    ApplicationArea = All;
                    Caption = 'employmentDate', Locked = true;
                }
                field(terminationDate; "Termination Date")
                {
                    ApplicationArea = All;
                    Caption = 'terminationDate', Locked = true;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                }
                field(birthDate; "Birth Date")
                {
                    ApplicationArea = All;
                    Caption = 'birthDate', Locked = true;
                }
                field(statisticsGroupCode; "Statistics Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'statisticsGroupCode', Locked = true;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
                part(picture; 5468)
                {
                    ApplicationArea = All;
                    Caption = 'picture';
                    EntityName = 'picture';
                    EntitySetName = 'picture';
                    SubPageLink = Id = FIELD(Id);
                }
                part(defaultDimensions; 5509)
                {
                    ApplicationArea = All;
                    Caption = 'Default Dimensions', Locked = true;
                    EntityName = 'defaultDimensions';
                    EntitySetName = 'defaultDimensions';
                    SubPageLink = ParentId = FIELD(Id);
                }
                part(timeRegistrationEntries; 20041)
                {
                    ApplicationArea = All;
                    Caption = 'timeRegistrationEntries', Locked = true;
                    EntityName = 'timeRegistrationEntry';
                    EntitySetName = 'timeRegistrationEntries';
                    SubPageLink = "Employee Id" = FIELD(Id);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
        RecRef: RecordRef;
    begin
        INSERT(TRUE);

        GraphMgtEmployee.ProcessComplexTypes(Rec, PostalAddressJSON);

        RecRef.GETTABLE(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CURRENTDATETIME());
        RecRef.SETTABLE(Rec);

        MODIFY(TRUE);
        SetCalculatedFields();
        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Employee: Record "Employee";
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        IF xRec.Id <> Id THEN
            GraphMgtGeneralTools.ErrorIdImmutable();
        Employee.SETRANGE(Id, Id);
        Employee.FINDFIRST();

        GraphMgtEmployee.ProcessComplexTypes(Rec, PostalAddressJSON);

        IF "No." = Employee."No." THEN
            MODIFY(TRUE)
        ELSE BEGIN
            Employee.TRANSFERFIELDS(Rec, FALSE);
            Employee.RENAME("No.");
            TRANSFERFIELDS(Employee);
        END;

        SetCalculatedFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    trigger OnOpenPage()
    var
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
    begin
        GraphMgtEmployee.UpdateIntegrationRecords(TRUE);
    end;

    var
        TempFieldSet: Record 2000000041 temporary;
        PostalAddressJSON: Text;
        DisplayName: Text;

    local procedure SetCalculatedFields()
    var
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
    begin
        PostalAddressJSON := GraphMgtEmployee.PostalAddressToJSON(Rec);
        DisplayName := STRSUBSTNO('%1 %2', "First Name", "Last Name");
    end;

    local procedure ClearCalculatedFields()
    begin
        CLEAR(Id);
        CLEAR(PostalAddressJSON);
        TempFieldSet.DELETEALL();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        IF TempFieldSet.GET(DATABASE::Employee, FieldNo) THEN
            EXIT;

        TempFieldSet.INIT();
        TempFieldSet.TableNo := DATABASE::Employee;
        TempFieldSet.VALIDATE("No.", FieldNo);
        TempFieldSet.INSERT(TRUE);
    end;
}
