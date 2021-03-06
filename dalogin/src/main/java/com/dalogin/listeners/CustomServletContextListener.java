package com.dalogin.listeners;


import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.file.NoSuchFileException;

/**
 * @author George Gaspar
 * @email: igeorge1982@gmail.com 
 * 
 * @Year: 2015
 */

import java.sql.SQLException;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import org.apache.log4j.Logger;
import com.google.common.collect.Multimap;
import com.google.common.collect.Multimaps;
import com.google.common.collect.TreeMultimap;
import com.dalogin.DBConnectionManager;
import com.dalogin.UrlManager;
import com.dalogin.utils.PropertyUtils;


@WebListener
public class CustomServletContextListener implements ServletContextListener{
	
	/**
	 * 
	 */
	private static Logger log = Logger.getLogger(Logger.class.getName());

	/**
	 * 
	 */
	private volatile static ConcurrentHashMap<String, Object> activeUsers;
	
	/**
	 * 
	 */
	private static volatile Multimap<String, String> sessions;
	
	/**
	 * 
	 */
	private static volatile HashMap<String,String> attributes;
	
	/**
	 * 
	 */
	private static volatile HashMap<String,String> urls;

	public static String gmail_password = null;
	public static String gmail_username = null;
	public static String gmail_smtp = null;
	
	/**
	 * 
	 */
   public void contextInitialized(ServletContextEvent event) {
    
	ServletContext context = event.getServletContext();
	
	try {
		ClassLoader cl = this.getClass().getClassLoader();
		InputStream is = cl.getResourceAsStream("properties.properties");

		DataInputStream in = new DataInputStream(is);
		BufferedReader br = new BufferedReader(new InputStreamReader(in));
		PropertyUtils.loadPropertyFile("properties.properties", br);
		
		gmail_password = PropertyUtils.getProperty("gmail_password");
		gmail_username = PropertyUtils.getProperty("gmail_username");
		gmail_smtp = PropertyUtils.getProperty("gmail_smtp");
		
		in.close();
		br.close();
		
		} catch (Exception e) {
			
		System.err.println(e.getMessage());
	}
    
	/*
	 * dB parameters loaded from web.xml 
	 */
   	final String url = context.getInitParameter("DBURL");
   	final String u = context.getInitParameter("DBUSER");
   	final String p = context.getInitParameter("DBPWD");
   	
   	/*
   	 * timeOut parameter for session creation (& to prevent playback attacks)
   	 */
   	final String time = context.getInitParameter("TIME");
    context.setAttribute("time", time);

   	/*
   	 * uRL parameters loaded from web.xml
   	 */
	final String voucherRedirect = context.getInitParameter("voucherRedirect");
	final String voucherElseRedirect = context.getInitParameter("voucherElseRedirect");
	final String homePage = context.getInitParameter("homePage");
	final String homePageIndex = context.getInitParameter("homePageIndex");
	final String loginContext = context.getInitParameter("loginContext");
	final String loginToRegister = context.getInitParameter("loginToRegister");
	final String loginToLogout = context.getInitParameter("loginToLogout");
	final String webApiContext = context.getInitParameter("webApiContext");
	final String webApiContextUrl = context.getInitParameter("webApiContextUrl");
	
	/* loading the context InitParameters once, then putting them into HashMap<String, String> that is set to context then, 
	*  using an UrlManager class that initialize all the urls and has getter / setter methods.
	*/
	
	/* Urls are loadable from context scope or at class level with "getServletContext().getInitParameter("voucherRedirect");".
	* The purpose of the context scope is to make editable the urls during runtime, through an API later.
	*/
	
	//TODO: set the edited urls as new InitParameter value
	
	UrlManager urlManager = new UrlManager(voucherRedirect, voucherElseRedirect, homePage, homePageIndex, loginContext, loginToRegister, loginToLogout, webApiContextUrl, webApiContext);
   	
    urls = new HashMap<String, String>();

   	String voucherRedirect_ = urlManager.getVoucherRedirect();
   	String voucherElseRedirect_ = urlManager.getVoucherElseRedirect();
	String homePage_ = urlManager.getHomePage();
	String homePageIndex_ = urlManager.getHomePageIndex();
	String loginContext_ = urlManager.getLoginContext();
	String loginToRegister_ = urlManager.getLoginToRegister();
	String loginToLogout_ = urlManager.getLoginToLogout();
	String webApiContext_ = urlManager.getWebApiContext();
	String webApiContextUrl_ = urlManager.getWebApiContextUrl();
	
   	urls.put(voucherRedirect, voucherRedirect_);
   	urls.put(voucherElseRedirect, voucherElseRedirect_);
   	urls.put(homePage, homePage_);
   	urls.put(homePageIndex, homePageIndex_);
   	urls.put(loginContext, loginContext_);
   	urls.put(loginToRegister, loginToRegister_);
   	urls.put(loginToLogout, loginToLogout_);
   	urls.put(webApiContext, webApiContext_);
   	urls.put(webApiContextUrl, webApiContextUrl_);

   	context.setAttribute("UrlManager", urls);

   	//create database connection from init parameters and set it to context
   	DBConnectionManager dbManager = new DBConnectionManager(url, u, p);
   	context.setAttribute("DBManager", dbManager);
   	log.info("Database connection initialized for Application.");

       //
       // instanciate a map to store references to all the active
       // sessions and bind it to context scope.
       //
       activeUsers = new ConcurrentHashMap<String, Object>();
       context.setAttribute("activeUsers", activeUsers);
       
       attributes = new HashMap<String, String>();
       context.setAttribute("attributes", attributes); 
       
       sessions = Multimaps.synchronizedSortedSetMultimap(TreeMultimap.create());
       context.setAttribute("sessions", sessions);
       
	   //PBI: resolve dependencies for WildFly, smoothly
       //WS SOAP taken out due to dependency conflict on WildFly. 
       //put it here 
   }

   /**
    * Needed for the ServletContextListener interface.
    */
   public void contextDestroyed(ServletContextEvent event){
       
	   // To overcome the problem with losing the session references
       // during server restarts, put code here to serialize the
       // activeUsers HashMap.  Then put code in the contextInitialized
       // method that reads and reloads it if it exists...
	   
	ServletContext context = event.getServletContext();
   	
	DBConnectionManager dbManager = (DBConnectionManager) context.getAttribute("DBManager");
   	try {
   		dbManager.closeConnection();  			
   			} catch (SQLException e) {
   				log.error(e.getLocalizedMessage());
	}
   	log.info("Database connection closed for Application.");
   
   }
}


