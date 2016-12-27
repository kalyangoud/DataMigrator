Public with sharing class ExampleController {
    Public List<account> Account_List{get;set;}
    Public List<string> Country_List{get;set;}
    
    Public ExampleController (){
        Account_List = New list<account>();
        Account_List = [Select name,accountNumber from account limit 5];
        Country_List = New List<string>();
        Country_List.add('India');
        Country_List.add('United Kingdom');
        Country_List.add('United States');
        Country_List.add('Singapore');
        Country_List.add('Spain');
    } 
}