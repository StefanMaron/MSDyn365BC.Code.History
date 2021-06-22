page 5483 "Employee Entity"
{
    Caption = 'employees', Locked = true;
    DelayedInsert = true;
    EntityName = 'employee';
    EntitySetName = 'employees';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = Employee;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                }
                field(displayName; DisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                    Editable = false;
                }
                field(givenName; "First Name")
                {
                    ApplicationArea = All;
                    Caption = 'GivenName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("First Name"));
                    end;
                }
                field(middleName; "Middle Name")
                {
                    ApplicationArea = All;
                    Caption = 'MiddleName', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Middle Name"));
                    end;
                }
                field(surname; "Last Name")
                {
                    ApplicationArea = All;
                    Caption = 'Surname', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Last Name"));
                    end;
                }
                field(jobTitle; "Job Title")
                {
                    ApplicationArea = All;
                    Caption = 'JobTitle', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Job Title"));
                    end;
                }
                field(address; PostalAddressJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Address', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the address for the employee.';
                }
                field(phoneNumber; "Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'PhoneNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Phone No."));
                    end;
                }
                field(mobilePhone; "Mobile Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'MobilePhone', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Mobile Phone No."));
                    end;
                }
                field(email; "Company E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'Email', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Company E-Mail"));
                    end;
                }
                field(personalEmail; "E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'PersonalEmail', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("E-Mail"));
                    end;
                }
                field(employmentDate; "Employment Date")
                {
                    ApplicationArea = All;
                    Caption = 'EmploymentDate', Locked = true;
                }
                field(terminationDate; "Termination Date")
                {
                    ApplicationArea = All;
                    Caption = 'TerminationDate', Locked = true;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status', Locked = true;
                }
                field(birthDate; "Birth Date")
                {
                    ApplicationArea = All;
                    Caption = 'BirthDate', Locked = true;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
                part(picture; "Picture Entity")
                {
                    ApplicationArea = All;
                    Caption = 'picture';
                    EntityName = 'picture';
                    EntitySetName = 'picture';
                    SubPageLink = Id = FIELD(Id);
                }
                part(defaultDimensions; "Default Dimension Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Default Dimensions', Locked = true;
                    EntityName = 'defaultDimensions';
                    EntitySetName = 'defaultDimensions';
                    SubPageLink = ParentId = FIELD(Id);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
        RecRef: RecordRef;
    begin
        Insert(true);

        GraphMgtEmployee.ProcessComplexTypes(Rec, PostalAddressJSON);

        RecRef.GetTable(Rec);
        GraphMgtGeneralTools.ProcessNewRecordFromAPI(RecRef, TempFieldSet, CurrentDateTime);
        RecRef.SetTable(Rec);

        Modify(true);
        SetCalculatedFields;
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Employee: Record Employee;
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if xRec.Id <> Id then
            GraphMgtGeneralTools.ErrorIdImmutable;
        Employee.SetRange(Id, Id);
        Employee.FindFirst;

        GraphMgtEmployee.ProcessComplexTypes(Rec, PostalAddressJSON);

        if "No." = Employee."No." then
            Modify(true)
        else begin
            Employee.TransferFields(Rec, false);
            Employee.Rename("No.");
            TransferFields(Employee);
        end;

        SetCalculatedFields;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
    end;

    trigger OnOpenPage()
    var
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
    begin
        GraphMgtEmployee.UpdateIntegrationRecords(true);
    end;

    var
        TempFieldSet: Record "Field" temporary;
        PostalAddressJSON: Text;
        DisplayName: Text;

    local procedure SetCalculatedFields()
    var
        GraphMgtEmployee: Codeunit "Graph Mgt - Employee";
    begin
        PostalAddressJSON := GraphMgtEmployee.PostalAddressToJSON(Rec);
        DisplayName := StrSubstNo('%1 %2', "First Name", "Last Name");
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(Id);
        Clear(PostalAddressJSON);
        TempFieldSet.DeleteAll();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    begin
        if TempFieldSet.Get(DATABASE::Employee, FieldNo) then
            exit;

        TempFieldSet.Init();
        TempFieldSet.TableNo := DATABASE::Employee;
        TempFieldSet.Validate("No.", FieldNo);
        TempFieldSet.Insert(true);
    end;
}

