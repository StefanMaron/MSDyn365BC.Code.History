report 17350 "Change Person Name"
{
    Caption = 'Change Person Name';
    ProcessingOnly = true;

    dataset
    {
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
                    field("Person.""First Name"""; Person."First Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Current First Name';
                        Editable = false;
                    }
                    field("Person.""Middle Name"""; Person."Middle Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Current Middle Name';
                        Editable = false;
                    }
                    field("Person.""Last Name"""; Person."Last Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Current Last Name';
                        Editable = false;
                    }
                    field(NewFirstName; NewFirstName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New First Name';
                    }
                    field(NewMiddleName; NewMiddleName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Middle Name';
                    }
                    field(NewLastName; NewLastName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Last Name';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(OrderDate; OrderDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order Date';
                    }
                    field(OrderNo; OrderNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order No.';
                        ToolTip = 'Specifies the number of the related order.';
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the record or entry.';
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

    trigger OnPreReport()
    begin
        if NewFirstName = '' then
            Error(Text001);

        if NewMiddleName = '' then
            Error(Text002);

        if NewLastName = '' then
            Error(Text003);

        if StartDate = 0D then
            Error(Text004);

        if OrderDate = 0D then
            Error(Text005);

        if OrderNo = '' then
            Error(Text006);

        if Person."No." = '' then
            Error(Text008);

        if Person.GetFullName = GetFullName then
            Error(Text002);

        if not HideDialog then
            if not Confirm(Text012, true, Person.GetFullName, GetFullName, StartDate) then
                CurrReport.Quit;

        ChangePersonName.ChangeName(
          Person."No.",
          NewFirstName,
          NewMiddleName,
          NewLastName,
          OrderNo,
          OrderDate,
          StartDate,
          Description);
    end;

    var
        Person: Record Person;
        ChangePersonName: Codeunit "Change Person Name";
        NewFirstName: Text[30];
        NewMiddleName: Text[30];
        NewLastName: Text[30];
        Description: Text[50];
        OrderNo: Code[20];
        OrderDate: Date;
        StartDate: Date;
        Text001: Label 'You must specify New First Name.';
        Text002: Label 'You must specify New Middle Name.';
        Text003: Label 'You must specify New Last Name.';
        Text004: Label 'You must specify Start Date.';
        Text005: Label 'You must specify Order Date.';
        Text006: Label 'You must specify Order No.';
        Text008: Label 'Person is not defined.';
        HideDialog: Boolean;
        Text012: Label 'Person name %1 will be changed to\%2 from date %3. Continue?';

    [Scope('OnPrem')]
    procedure SetPerson(NewPerson: Record Person)
    begin
        Person := NewPerson;
    end;

    [Scope('OnPrem')]
    procedure SetParameters(Person2: Record Person; FirstName2: Text[30]; MiddleName2: Text[30]; LastName2: Text[30]; OrderNo2: Code[20]; OrderDate2: Date; StartDate2: Date; HideDialog2: Boolean; Description2: Text[50])
    begin
        Person := Person2;
        NewFirstName := FirstName2;
        NewMiddleName := MiddleName2;
        NewLastName := LastName2;
        OrderDate := OrderDate2;
        OrderNo := OrderNo2;
        StartDate := StartDate2;
        HideDialog := HideDialog2;
        Description := Description2;
    end;

    local procedure GetFullName(): Text[100]
    begin
        exit(NewLastName + ' ' + NewFirstName + ' ' + NewMiddleName);
    end;
}

