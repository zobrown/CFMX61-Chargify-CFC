<cfcomponent hint="Chargify wrapper component based on Component https://github.com/GenuineParts/Chargify-Coldfusion-Component">
	<cfif (not isdefined('variables.initialized')) or (not variables.initialized) >
		<cfscript>
			variables.username = "";
			variables.domain = ""; 
			variables.password = "";
			variables.json = createObject('component','json');
			variables.initialized = false;
			variables.statuscode = "200";
		</cfscript>
	</cfif>

	<cffunction name="init" access="public" returnType="any" output="no" hint="initializes the component">
		<cfargument name="username" required="false" default="" hint="Generated from https://apps.chargify.com">
		<cfargument name="domain" required="false" default="" hint="">
		<cfargument name="password" required="false" default="" hint="">

		<cfscript>
			variables.username = arguments.username;
			variables.domain = arguments.domain; 
			variables.password = arguments.password;
			variables.json = createObject('component','json');
			variables.initialized = true;
		</cfscript>

		<cfreturn this>
	</cffunction>

	<cffunction name="getStatusCode" access="public" returntype="string" hint="Call this after using a rest API function to determine if it was successful">
		<cfreturn variables.statuscode>
	</cffunction>
	
	<cffunction name="deserializeJSON" access="private" hint="Internal function for deserializing JSON">
		<cfargument name="indata">
		
		<cftry>
			<cfreturn variables.json.decode(arguments.indata)>
		<cfcatch>
			<cfreturn arguments.indata>
		</cfcatch>
		</cftry>
		<cfreturn variables.json.decode(arguments.indata.toString())>
	</cffunction>

	<cffunction name="serializeJSON" access="private" hint="Internal function for serializing JSON">
		<cfargument name="indata">
		<cfreturn variables.json.encode(data=arguments.indata,allKeyCase='lower')>
	</cffunction>

	<cffunction name="_request" access="private" hint="internal function that submit the raw request">
		<cfargument name="path">
		<cfhttp url="https://#variables.domain#.chargify.com/#arguments.path#.json" method="#arguments.method#" username="#variables.username#" password="#variables.password#">
			<cfhttpparam type="header" name="Content-Type" value="application/json" />
				<cfif arguments.method EQ "GET">
					<cfloop collection=#arguments# item="param">
						<cfhttpparam type="URL" name="#LCase(param)#" value="#StructFind(arguments, param)#">
					</cfloop>
				<cfelseif arguments.method NEQ "GET">
					<cfset jsonString = serializeJSON(arguments.obj)>
					<cfhttpparam type="Body" value="#jsonString#">
				</cfif>
	    </cfhttp>
		<cfset variables.statuscode = ListFirst(cfhttp.statusCode, " ")>
		<cfswitch expression="#ListFirst(cfhttp.statusCode, " ")#">
			<cfcase value="500">
				<!--- 500 INTERNAL SERVER ERROR --->
			</cfcase>
			<cfcase value="422">
				<!--- 422 UNPROCESSABLE ENTITY	 Sent in response to a POST (create) or PUT (update) request that is invalid. --->
			</cfcase>
			<cfcase value="404">
				<!--- 404 NOT FOUND	 The requested resource was not found. --->
			</cfcase>
			<cfcase value="403">
				<!--- 403 FORBIDDEN	 Returned by valid endpoints in our application that have not been enabled for API use. --->
			</cfcase>
			<cfcase value="401">
				<!--- 401 UNAUTHORIZED Returned when API authentication has failed. --->
			</cfcase>
			<cfcase value="201">
				<!--- 201 CREATED The resource was successfully created. Sent in response to a POST (create) request with valid data. --->
			</cfcase>
			<cfcase value="200">
				<!--- 200 OK The request succeeded and a response was sent. Usually in response to a GET (read) request, but also for successful PUT (update) requests.--->
			</cfcase>
			<cfdefaultcase>
				<!--- ???? --->
			    <cfmail to="zb185019@ncr.com" from="mh230120@ncr.com" subject="Chargify Unexpected Results" type="html">
			    	https://#variables.domain#.chargify.com/#arguments.path#.json<br/>

			    	#cfhttp.FileContent#<br/>
			    	#cfhttp.ErrorDetail#<br/>


			    </cfmail>
			</cfdefaultcase>
		</cfswitch>
	
		<cfreturn DeSerializeJSON(cfhttp.FileContent)>
	</cffunction>
	
	<cfscript>
	
	
	
		// CUSTOMERS
	
		function customerList() {
			return _request(
				path="customers",
				method="GET",
				argumentCollection=arguments
			);
		}
		
		// expects reference as an argument
		function customerDetail() {
			return _request(
				path="customers/#arguments.id#",
				method="GET",
				argumentCollection=arguments
			);
		}
		
		// expects a customer object in the form of a struct as the sole argument:
		/*
		{"customer":{
		  "first_name":"Joe",
		  "last_name":"Blow",
		  "email":"joe@example.com"
		}}
		*/
		function customerCreate() {
			return _request(
				path="customers",
				method="POST",
				obj=arguments.data
			);
		}
		
		// http://support.chargify.com/faqs/api/api-customers#api-usage-json-customers-update
		function customerUpdate() {
			return _request(
				path="customers/#arguments.id#",
				method="PUT",
				obj=arguments.data
			);
		}
		
		// PAYMENT_PROFILE
		function paymentProfileListAll() {
			return _request(
				path="payment_profiles",
				method="GET",
				argumentCollection=arguments
			);
		}

		// expects a payment id as "id"
		function paymentProfileDetail() {
			return _request(
				path="payment_profiles/#arguments.id#",
				method="GET"
			);
		}
		
		// expects a payment id as "id"
		function paymentProfileUpdate() {
			return _request(
				path="payment_profiles/#arguments.id#",
				method="PUT",
				obj=arguments.data
			);
		}


		// SUBSCRIPTIONS
		
		function subscriptionListAll() {
			return _request(
				path="subscriptions",
				method="GET",
				argumentCollection=arguments
			);
		}
	
		// expects a Chargify customer id as "id"
		function subscriptionListByCustomer() {
			return _request(
				path="customers/#arguments.id#/subscriptions",
				method="GET"
			);
		}
		
		// expects a Chargify subscription id as "id"
		function subscriptionDetail() {
			return _request(
				path="subscriptions/#arguments.id#",
				method="GET"
			);
		}
		
		// expects a subscription object in the form of a struct as the sole argument:
		// see http://support.chargify.com/faqs/api/api-subscriptions#api-usage-json-subscriptions-create
		/*
		{"subscription":{
	        "product_handle":"[@product.handle]",
	        "customer_attributes":{
	          "first_name":"Joe",
	          "last_name":"Blow",
	          "email":"joe@example.com"
	        },
	        "credit_card_attributes":{
	          "full_number":"1",
	          "expiration_month":"10",
	          "expiration_year":"2020"
	        }
	      }}
		*/
		function subscriptionCreate() {
			return _request(
				path="subscriptions",
				method="POST",
				obj=arguments.data
			);
		}
		
		// http://support.chargify.com/faqs/api/api-subscriptions#api-usage-json-subscriptions-update
		function subscriptionUpdate() {
			return _request(
				path="subscriptions/#arguments.id#",
				method="PUT",
				obj=arguments.data
			);
		}
		
		// http://support.chargify.com/faqs/api/api-prorated-upgrades-downgrades
		function subscriptionMigrate() {
			return _request(
				path="subscriptions/#arguments.id#/migrations",
				method="POST",
				obj=arguments.data
			);
		}
		
		// http://support.chargify.com/faqs/api/api-subscriptions#api-usage-json-subscriptions-delete
		function subscriptionCancel() {
			return _request(
				path="subscriptions/#arguments.id#",
				method="DELETE",
				obj=arguments.data
			);
		}
		
		
		// expects a Chargify product family id as "id"
		function componentListByProductFamily() {
			return _request(
				path="product_families/#arguments.id#/components",
				method="GET"
			);
		}
		
		// subscriptions/[subscription_id]/components/[component_id].[format]
		function componentUpdateUsage() {
			return _request(
				path="subscriptions/#arguments.subsid#/components/#arguments.compid#",
				method="PUT",
				obj=arguments.data
			);
		}
		
		// /subscriptions/[@subscription.id]/components/[@component.id]/usages.json
		function componentUpdateMetered() {
			return _request(
				path="subscriptions/#arguments.subsid#/components/#arguments.compid#/usages",
				method="POST",
				obj=arguments.data
			);
		}
		
		
		// expects a Chargify subscription id as "id"
		function componentListBySubscription() {
			return _request(
				path="subscriptions/#arguments.id#/components",
				method="GET"
			);
		}
		
		// PRODUCTS
		
		function productListAll() {
			return _request(
				path="products",
				method="GET"
			);
		}
				 
		function productFamilyListAll() {
			return _request(
				path="product_families",
				method="GET"
			);
		}

		
	</cfscript>

</cfcomponent>