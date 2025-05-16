#!/bin/bash
# Function to show spiner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c] Building... " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "    \r"
}

# Request project name
echo -n "📝 Enter project name: "
read -r project_name

# Validate empty name
if [ -z "$project_name" ]; then
    echo ""
    echo "❌ Error: You need enter project name."
    exit 1
fi

# Validate if project exists
if [ -d "$project_name" ]; then
    echo ""
    echo "Error: Project '$project_name' aready exists."
    exit 1
fi

echo ""
echo "🛠️ Building project: $project_name"

# Creating structure of directories
mkdir -p "$project_name"/{admon-"$project_name"/{app/{ajax,controllers,models,views/{lang/{es,en},modules,pages/sections}},public/{css/{plugins,scss},img/icons/{android,apple},js/helpers,webfonts}},app/{ajax,controllers,models,views/{lang/{es,en},modules,pages/sections}},core/{class,libs/{PHPMailer,FPDF,MultiCell}},DB,public/{css/{plugins,scss},img/icons/{android,apple},js/helpers,webfonts}} 2>/dev/null

#############################
# Creating files with content
#############################

# /core/class
# Config.php
cat > "$project_name/core/class/Config.php" << 'EOF'
<?php
class Config {
    // Constructor
    function __construct( $session = false, $timezone = '' ) {
        if ( $session ) {
            session_set_cookie_params(60*60*24*1);
            // session_set_cookie_params(180);
            session_start();
        }
        date_default_timezone_set( $timezone );
    }

    public static function getConfig( $paths = NULL ) {
        if ( $paths ) {
            $config = $GLOBALS['config'];
            $paths = explode( '/', $paths );

            foreach( $paths as $path ) {
                $config = $config[$path];
            }
            return $config;
        }
        return false;
    }
}
EOF

# Connection.php
cat > "$project_name/core/class/Connection.php" << 'EOF'
<?php
class Connection {
  public static function connect() {
    $conn = new PDO(
      'mysql:host='.Config::getConfig('mysql/host').';dbname='.Config::getConfig('mysql/dbname').'',
      Config::getConfig('mysql/usr'),
      Config::getConfig('mysql/psw'),
      array (
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8'
      )
    );
    return $conn;
  }
}
EOF

# Email.php
cat > "$project_name/core/class/Email.php" << 'EOF'
<?php
use PHPMailer\PHPMailer\PHPMailer;

class Email extends Template {
    private $name,
        $phone,
        $email,
        $subject,
        $message;

    function __construct( $name, $phone, $email, $subject, $message ) {
        $this->$name = $name;
        $this->$phone = $phone;
        $this->$email = $email;
        $this->$subject = $subject;
        $this->$message = $message;
    }

    //============== METHOD TO SEND EMAIL
    function sendEmail() {
        require_once 'core/libs/PHPMailer/PHPMailer.php';
        require_once 'core/libs/PHPMailer/Exception.php';

        $mail = new PHPMailer();
        $mail->Charset = 'utf-8';
        $mail->Debugoutput = 'html';

        //--- smpt settings
        $mail->isMail();
        $mail->setFrom($this->email, $this->name);
        $mail->addReplyto('frankenstein291294@gmail.com');
        $mail->isHTML(true);
        $mail->Subject = $this->subject;
        $mail->addAddress('frankenstein291294@gmail.com');

        $mail->Body = '<!DOCTYPE html>
            <html lang="'.$this->lang.'">
            <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Formulario de contacto Optica Solution</title>
            </head>
            <body>
            <div style="padding: 20px; border: 1px solid rgba(0,0,0,.3)">
            <img src="https://opticasolution.com//public/img/logo.png" alt="Logo Oficial" width="200px" height="auto">
            <h2>Formulario de contacto Optica Solution</h2>
            <hr style="height: 2px; background: skyblue">
            <h4><strong style="color:#777">Nombre: </strong>'.$this->name.'</h4>
            <h4><strong style="color:#777">Teléfono: </strong>'.$this->phone.'</h4>
            <h4><strong style="color:#777">Correo: </strong>'.$this->email.'</h4>

            <h4><strong style="color:#777">Mensaje: </strong>'. nl2br( $this->message ) .'</h4>

            </div>
            </body>
            </html>';

        if ( $mail->send() ) {
            return true;
        } else {
            return false;
        }
    }
}
EOF

# Format.php
cat > "$project_name/core/class/Format.php" << 'EOF'
<?php
class Format extends Template {
    //=========== CONSTRUCT
    function __construct( $lang ) {
        $this->lang = $lang;
    }

    //=========== METHODS
    /* METHOD TO FORMAT ARRAYS */
    public function formatArray ( $array ) {
        echo '<pre>';
        var_dump( $array );
        echo '</pre>';
    }

    /* METHOD TO FORMAT DATES */
    public function formatDate ( $date ) {
        if ( $this->getLang() == 'es' ) {
            $timestamp = strtotime( $date );
            $months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
            $day = date ( 'd', $timestamp );
            $month = date ( 'm', $timestamp ) - 1;
            $year = date ( 'Y', $timestamp );
            $formatDate = $day. ' de ' . $months[$month] . ' del ' . $year;
            return $formatDate;
        } else if ( $this->getLang() == 'en' ) {
            $timestamp = strtotime( $date );
            $months = ['January', 'Febrary', 'March', 'April', 'May', 'June', 'July', 'Aogust', 'September', 'October', 'November', 'December'];
            $day = date ( 'd', $timestamp );
            $month = date ( 'm', $timestamp ) - 1;
            $year = date ( 'Y', $timestamp );
            $formatDate = $day. ' of ' . $months[$month] . ' of ' . $year;
            return $formatDate;
        }
    }

    /* METHOD TO REMOVE ACCENTS */
    function removeAccents ( $string ) {
        $string = str_replace(
            array('á', 'à', 'ä', 'â', 'ª', 'Á', 'À', 'Â', 'Ä'),
            array('a', 'a', 'a', 'a', 'a', 'A', 'A', 'A', 'A'),
            $string
        );

        $string = str_replace(
            array('é', 'è', 'ë', 'ê', 'É', 'È', 'Ê', 'Ë'),
            array('e', 'e', 'e', 'e', 'E', 'E', 'E', 'E'),
            $string );

        $string = str_replace(
            array('í', 'ì', 'ï', 'î', 'Í', 'Ì', 'Ï', 'Î'),
            array('i', 'i', 'i', 'i', 'I', 'I', 'I', 'I'),
            $string );

        $string = str_replace(
            array('ó', 'ò', 'ö', 'ô', 'Ó', 'Ò', 'Ö', 'Ô'),
            array('o', 'o', 'o', 'o', 'O', 'O', 'O', 'O'),
            $string );

        $string = str_replace(
            array('ú', 'ù', 'ü', 'û', 'Ú', 'Ù', 'Û', 'Ü'),
            array('u', 'u', 'u', 'u', 'U', 'U', 'U', 'U'),
            $string );

        $string = str_replace(
            array('ñ', 'Ñ', 'ç', 'Ç'),
            array('n', 'N', 'c', 'C'),
            $string
        );

        return $string;
    }
}
EOF

# Helpers.php
cat > "$project_name/core/class/Helpers.php" << 'EOF'
<?php
class Helpers {
    public static function formatArray( $array ) {
        echo '<pre>';
        var_dump( $array );
        echo '</pre>';
    }

    public static function formatDate( $date ) {
        $timestamp = strtotime( $date );

        $months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
        $day = date ( 'd', $timestamp );
        $month = date ( 'm', $timestamp ) - 1;
        $year = date ( 'Y', $timestamp );

        $formatDate = $day. ' de ' . $months[$month] . ' del ' . $year;
        return $formatDate;
    }

    public static function removeAccents( $string ) {

        // $string = utf8_encode( $string );

        $string = str_replace(
            array('á', 'à', 'ä', 'â', 'ª', 'Á', 'À', 'Â', 'Ä'),
            array('a', 'a', 'a', 'a', 'a', 'A', 'A', 'A', 'A'),
            $string
        );

        $string = str_replace(
            array('é', 'è', 'ë', 'ê', 'É', 'È', 'Ê', 'Ë'),
            array('e', 'e', 'e', 'e', 'E', 'E', 'E', 'E'),
            $string );

        $string = str_replace(
            array('í', 'ì', 'ï', 'î', 'Í', 'Ì', 'Ï', 'Î'),
            array('i', 'i', 'i', 'i', 'I', 'I', 'I', 'I'),
            $string );

        $string = str_replace(
            array('ó', 'ò', 'ö', 'ô', 'Ó', 'Ò', 'Ö', 'Ô'),
            array('o', 'o', 'o', 'o', 'O', 'O', 'O', 'O'),
            $string );

        $string = str_replace(
            array('ú', 'ù', 'ü', 'û', 'Ú', 'Ù', 'Û', 'Ü'),
            array('u', 'u', 'u', 'u', 'U', 'U', 'U', 'U'),
            $string );

        $string = str_replace(
            array('ñ', 'Ñ', 'ç', 'Ç'),
            array('n', 'N', 'c', 'C'),
            $string
        );

        return $string;
    }
}
EOF

# Layout.php
cat > "$project_name/core/class/Layout.php" << 'EOF'
<?php
class Layout {
      //=========== PROPERTIES
    public $lang;
    public $routeFrontend;
    public $routeDashboard;
    public $routeBackend;

    //=========== CONSTRUCT
    public function __construct( $lang = null, $routeFrontend = null, $routeDashboard = null, $routeBackend = null ) {
        $this->lang = $lang;
        $this->routeFrontend = $routeFrontend;
        $this->routeDashboard = $routeDashboard;
        $this->routeBackend = $routeBackend;
    }

    //=========== GETTERS
    public function getLang() {
        return $this->lang;
    }

    function header ( $title = null, $description = null, $keywords = null, $url = null, $image = null ) {
        echo '<!DOCTYPE html>
            <html lang="es-mx">
            <head>
            <meta charset="UTF-8">

            <!-- META TAGS GENERAL -->
            <title>'.$title.'</title>
            <meta name="description" content="'. $description .'" />
            <meta name="keywords" content="'. $keywords .'" />

            <!--  METAVIEWPORT -->
            <meta name="viewport" content="width=device-width, initial-scale=1.0">

            <!-- GENERAL -->
            <meta name="sitedomain" content="'. $this->routeFrontend .'" />
            <meta name="organization" content="Hawaiian Frogs" />
            <meta name="designer" content="Fraalancer" />
            <meta name="robots" content="index,follow" />
            <meta name="revisit-after" content="15days" />
            <meta name="googlebot" content="index,follow" />
            <meta name="author" content="Fraalancer" />
            <meta name="copyright" content="Hawaiian Frogs" />
            <meta name="image" content="'. $this->routeFrontend . 'public/img/' . $image .'" />

            <!-- APPLE TOUCH ICON -->
            <link rel="apple-touch-icon" sizes="57x57" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-57x57.png">
            <link rel="apple-touch-icon" sizes="60x60" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-60x60.png">
            <link rel="apple-touch-icon" sizes="72x72" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-72x72.png">
            <link rel="apple-touch-icon" sizes="114x114" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-114x114.png">
            <link rel="apple-touch-icon" sizes="120x120" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-120x120.png">
            <link rel="apple-touch-icon" sizes="144x144" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-144x144.png">
            <link rel="apple-touch-icon" sizes="152x152" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-152x152.png">
            <link rel="apple-touch-icon" sizes="180x180" href="'. $this->routeFrontend .'public/img/icons/apple/apple-icon-180x180.png">

            <!-- MANIFEST -->
            <link rel="manifest" href="'. $this->routeFrontend .'public/img/icons/manifest.json">

            <!-- FAVICON -->
            <link rel="shortcut icon" type="image/png" sizes="16x16" href="'.$this->routeFrontend.'public/img/icons/favicon16x16.png" />
            <link rel="shortcut icon" type="image/png" sizes="32x32" href="'.$this->routeFrontend.'public/img/icons/favicon32x32.png" />
            <link rel="shortcut icon" type="image/png" sizes="96x96" href="'.$this->routeFrontend.'public/img/icons/favicon96x96.png" />

            <!-- THEME COLOR -->
            <meta name="theme-color" content="#80b90d" />

            <!-- TWITTER CARD -->
            <meta name="twitter:card" content="summary" />
            <meta name="twitter:title" content="'. $title .'" />
            <meta name="twitter:description" content="'. $description .'" />
            <meta name="twitter:site" content="'. $url .'" />
            <meta name="twitter:creator" content="" />
            <meta name="image" content="'. $this->routeFrontend . 'public' . '/img/' . $image .'" />

            <!-- OPEN DATA GRAHP -->
            <meta property="og:title" content="'. $title .'" />
            <meta property="og:description" content="'. $description .'" />
            <meta property="og:url" content="'. $url .'" />
            <meta property="og:type" content="website" />
            <meta property="og:site_name" content="'. $title .'" />
            <meta property="og:site" content="'. $this->routeFrontend . '" />
            <meta property="og:image" content="'. $this->routeFrontend . 'public/img/' . $image .'" />
            <meta property="og:image:alt" content="'. $title .'" />
            <meta property="fb:admins" content="" />
            <meta property="fb:app_id" content="" />

            <link rel="stylesheet" href="'.$this->routeFrontend.'public/css/plugins/all.css">
            <link rel="stylesheet" href="'.$this->routeFrontend.'public/css/style.css">

            <script>localStorage.setItem("route_frontend_hawaiin", "'.$this->routeFrontend.'")</script>

            <!-- Google tag (gtag.js) -->
            <script async src="https://www.googletagmanager.com/gtag/js?id=G-FNF6XB4195"></script>
            <script>
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag("js", new Date());

              gtag("config", "G-FNF6XB4195");
            </script>

        </head>
        <body><div class="overlay"></div>';
    }

    function loader () {
        echo '<div class="wrapper-content"><div class="loader">
                <div class="container-img">
                  <img src="'.$this->routeFrontend.'public/img/logo.png" alt="Logo oficial">
                </div>
                <div class="text-bouncing">
                  <p class="text" style="--i:1">C</p>
                  <p class="text" style="--i:2">a</p>
                  <p class="text" style="--i:3">r</p>
                  <p class="text" style="--i:4">g</p>
                  <p class="text" style="--i:5">a</p>
                  <p class="text" style="--i:6">n</p>
                  <p class="text" style="--i:7">d</p>
                  <p class="text" style="--i:8">o</p>
                  <p class="text" style="--i:9">.</p>
                  <p class="text" style="--i:10">.</p>
                  <p class="text" style="--i:11">.</p>
                </div>
            </div></div>';
    }

    function navigation() {
        $menus = ['productos', 'blog', 'videos', 'contacto'];
        @$route = explode( '/', $_GET['ruta'] )[0];

        if( $route ) {
            $active_home = '';
        } else {
            $active_home = 'active';
        }

        echo '<!-- Navigation -->
              <nav>
                <!-- Logo -->
                <div class="logo-section">
                  <div class="wrapper-img">
                    <a href="/" title="">
                      <img src="'.$this->routeFrontend.'public/img/logo.png" alt="logo oficial">
                    </a>
                  </div>
                </div>

                <!-- Menu navigation -->
                <ul class="navigation"> 
                    <li><a href="'.$this->routeFrontend.'" title="Inicio" class="'.$active_home.'">Incio</a></li>';

                    foreach ($menus as $key => $menu) {

                        if ( $menu === @$route ) {

                            echo '<li><a href="'.$this->routeFrontend. $menu.'" title="Inicio" class="active">'. $menu .'</a></li>';

                        } else {

                            echo '<li><a href="'.$this->routeFrontend . $menu.'" title="Inicio" class="">'. $menu .'</a></li>';
                        }

                        
                    }

                    echo '<div class="login" action="">';
                        if ( isset($_SESSION['hawaiin_login_front']) ) {

                            // var_dump($_SESSION);
                            echo '<div class="img-user">
                                    <img src="'.$this->routeBackend.'public/img/users/'.$_SESSION['image_user_front_hawaiin'].'" alt="'.$_SESSION['name_user_front_hawaiin'].'">


                                    <div class="content-info-user">
                                        <div class="wrapper-info-user">
                                            <ul>
                                                <li><p class="name-user">'.$_SESSION['name_user_front_hawaiin'].'</p></li>
                                                <li><a href="'.$this->routeFrontend.'perfil/'.$_SESSION['id_user_front_hawaiin'].'" title="Perfil" id="btnProfile">Perfil</a></li>
                                                <hr/>
                                                <li><p id="closeSession2">Cerrar sesión</p></li>
                                            </ul>
                                        </div>
                                    </div>
                                </div>';

                        } else {
                            echo '<button id="login2">Iniciar sesion</button>';
                        }
                      echo '<!--<label for="search"><i class="fas fa-search"></i></label>
                      <input id="" type="text" name="search" placeholder="Busqueda">-->
                    </div>
                </ul>

                <!-- Search -->
                <div class="login" action="">';
                    if ( isset($_SESSION['hawaiin_login_front']) ) {

                        // var_dump($_SESSION);
                        echo '<div class="img-user2">
                                <img src="'.$this->routeBackend.'public/img/users/'.$_SESSION['image_user_front_hawaiin'].'" alt="'.$_SESSION['name_user_front_hawaiin'].'">


                                <div class="content-info-user2">
                                    <div class="wrapper-info-user">
                                        <ul>
                                            <li><p class="name-user">'.$_SESSION['name_user_front_hawaiin'].'</p></li>
                                            <li><a href="'.$this->routeFrontend.'perfil/'.$_SESSION['id_user_front_hawaiin'].'" title="Perfil" id="btnProfile">Perfil</a></li>
                                            <hr/>
                                            <li><p id="closeSession">Cerrar sesión</p></li>
                                        </ul>
                                    </div>
                                </div>
                            </div>';

                    } else {
                        echo '<button id="login">Iniciar sesion</button>';
                    }
                  echo '<!--<label for="search"><i class="fas fa-search"></i></label>
                  <input id="" type="text" name="search" placeholder="Busqueda">-->
                </div>

                <div class="menu-mobile">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </nav>';
    }

    function headerTop () {
        echo '  <!-- Header -->
                  <header>

                    <!-- Header top -->
                    <div class="header-top">
                      
                      <!-- Header top left -->
                      <div class="header-left">
                        <!--<ul>
                          <li><a href="" title="">Noticias</a></li>
                          <li><a href="" title="">Promociones</a></li>
                          <li><a href="" title="">Blog</a></li>
                        </ul>-->
                      </div>

                      <!-- Header top right -->
                      <div class="header-right">
                        <ul>
                          <li><a href="https://www.facebook.com/profile.php?id=100057629672564" title="Visitanos en facebook" target="_blank" rel="noopener"><i class="fa-brands fa-facebook"></a></i></li>
                          <li><a href="" title="Visitanos en Instagram" target="_blank" rel="noopener"><i class="fa-brands fa-instagram"></a></i></li>
                          <li><a href="" title="Visitanos en Youtube" target="_blank" rel="noopener"><i class="fa-brands fa-youtube"></a></i></li>
                          <li><a href="" title="Visitanos en Tiktok" target="_blank" rel="noopener"><i class="fa-brands fa-tiktok"></a></i></li>
                        </ul>
                      </div>
                    </div>

                  </header>';
    }

    function sidebar ( $route = null, $table = null, $section = null ) {
        $class = '';
        if ( !$route ) $class = 'active';

        echo '<div class="sidebar">
            <div class="wrapper-sidebar">
                <div class="title-sidebar"><h3>Categorias</h3></div>
                <hr>

                <ul class="content-item-sidebar">
                    <li class="item-sidebar"><a class="'.$class.'" href="'. $this->routeFrontend . $section . '" title="">Todas</a></li>';

                    $categories = Queries::mdlSelect( $table );

                    foreach ($categories as $key => $category) {
                        if ( $route === $category['url'] ) {

                            echo '<li class="item-sidebar"><a class="active" href="'. $this->routeFrontend . $section . '/'. $category['url'] .'" title="'. $category['name'] .'">'. $category['name'] .'</a></li>';

                        } else {

                            echo '<li class="item-sidebar"><a class="" href="'. $this->routeFrontend . $section . '/'. $category['url'] .'" title="'. $category['name'] .'">'. $category['name'] .'</a></li>';

                        }

                    }

                echo  '</ul>
            </div>
        </div>';
    }

    function  share ( $link = null, $title = null, $id_product = null, $id_user = null )  {
        $likes = Queries::mdlSelect('likes', 'id_product', $id_product);
        $new_likes = [];

        for ($i=0; $i<count( $likes ); $i++) {
            if ( $likes[$i]['likes'] === 1 ) {
                array_push( $new_likes, $likes[$i] );
            }
        }

        $liked = [];

        foreach ($new_likes as $key => $like) {
            if ( $like['id_user'] === $id_user ) {
                array_push( $liked, 'liked' );
            }
        }

        echo '<div class="content-social">
                <div class="wrapper-social">
                    <ul class="content-icons">
                        <li class="items-icons link-comment btnLike" id="like" idUser="'. $id_user .'" idProduct="'. $id_product .'" liked="'. count( $liked ) .'">
                            ';

                            if ( count( $liked ) > 0 ) echo '<i style="color: var(--font-color2)" class="fa-regular fa-thumbs-up"></i><p style="color: var(--font-color2)" class="number-like">'. count( $new_likes ) .'</p>';
                            else echo '<i class="fa-regular fa-thumbs-up"></i><p class="number-like">'. count( $new_likes ) .'</p>';

                            echo '
                        </li>
                    
                        <li class="items-icons" id="share"><i class="fa fa-share-nodes"></i>
                            <ul class="content-share">
                                <li class="item-share">
                                    <a 
                                        href="https://api.whatsapp.com/send?text='. $link .'" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="whatsapp"
                                    ><i class="fa-brands fa-whatsapp"></i></a>
                                </li>

                                <li class="item-share">
                                    <a 
                                        href="http://www.facebook.com/sharer.php?u='. $link .'&t='. $title .'" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="facebook"><i class="fa-brands fa-facebook"></i></a>
                                </li>

                                <li class="item-share">
                                    <a 
                                        href="https://twitter.com/intent/tweet?text=HawaiinFrogs&url='. $link .'&via=HawaiinFrogs&hashtags=#HawaiinFrogs" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="twitter"><i class="fa-brands fa-twitter"></i></a>
                                </li>

                                <li class="item-share">
                                    <a 
                                        href="http://www.linkedin.com/shareArticle?url='. $link .'" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="linkedin"><i class="fa-brands fa-linkedin"></i></a>
                                </li>

                            </ul>
                        </li>
                    </ul>
                </div>
            </div>';
    }

    function  share2 ( $link = null, $title = null, $id_product = null, $id_user = null )  {
        $likes = Queries::mdlSelect('likes', 'id_product', $id_product);
        $new_likes = [];

        for ($i=0; $i<count( $likes ); $i++) {
            if ( $likes[$i]['likes'] === 1 ) {
                array_push( $new_likes, $likes[$i] );
            }
        }

        $liked = [];

        foreach ($new_likes as $key => $like) {
            if ( $like['id_user'] === $id_user ) {
                array_push( $liked, 'liked' );
            }
        }

        echo '<div class="content-social2">
                <div class="wrapper-social">
                            <ul class="content-share">
                                <p>Compartir:</p>
                                <li class="item-share">
                                    <a 
                                        href="https://api.whatsapp.com/send?text='. $link .'" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="whatsapp"
                                    ><i class="fa-brands fa-whatsapp"></i></a>
                                </li>

                                <li class="item-share">
                                    <a 
                                        href="http://www.facebook.com/sharer.php?u='. $link .'&t='. $title .'" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="facebook"><i class="fa-brands fa-facebook"></i></a>
                                </li>

                                <li class="item-share">
                                    <a 
                                        href="https://twitter.com/intent/tweet?text=HawaiinFrogs&url='. $link .'&via=HawaiinFrogs&hashtags=#HawaiinFrogs" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="twitter"><i class="fa-brands fa-twitter"></i></a>
                                </li>

                                <li class="item-share">
                                    <a 
                                        href="http://www.linkedin.com/shareArticle?url='. $link .'" 
                                        target="_blank" 
                                        rel="noopener" 
                                        class="linkedin"><i class="fa-brands fa-linkedin"></i></a>
                                </li>

                            </ul>
                </div>
            </div>';
    }

    function comments ( $id ) {
        $comments = Queries::mdlSelect('comments', 'id_product', $id, 'id', 'desc');
        $arr_comments = [];

        foreach ($comments as $key => $comment) {
            if ( !$comment['id_parent'] )
                array_push( $arr_comments, $comment );
        }

        echo '<div id="comments">
                <div class="wrapper-comments">
                    <div class="title-comments"><h1>Comentarios</h1></div>
                    <hr>

                    <div class="create-comment">
                        <textarea cols="10" rows="3" placeholder="Ingrese comentario" id="comment_area"></textarea>
                        <button id="createComment">Commentar</button>
                    </div>
                    <input type="hidden" id="idProduct" value="'.$id.'">
                    <input type="hidden" id="idUser" value="'.@$_SESSION['id_user_front_hawaiin'].'">
                    <div class="errors"></div>';

                    foreach ($comments as $key => $comment) {
                        $user = Queries::mdlSelect('users', 'id', $comment['id_user']);
                        $img_user = $user[0]['image'];
                        $username =  explode( '@', $user[0]['user'] )[0];

                        echo '<div class="items-comments">
                                <input type="hidden" id="user" value="'.$user[0]['user'].'">
                                <div class="user-img"><img src="'.$this->routeBackend.'public/img/users/'.$img_user.'" alt=""></div>
                                <div class="body-comment">
                                    <div class="name-user">
                                        <span>'.$username.'</span>
                                    </div>
                                    <div class="comment">
                                        <p>'.$comment['comment'].'</p>
                                    </div>
                                    <span class="date">'.$comment['register_date'].'</span><button class="reply">Responder</button>
                                    <div class="respond">
                                        <textarea cols="10" rows="1" placeholder="Ingrese comentario"></textarea>
                                        <button class="reply-comment" id_parent="'.$comment['id'].'" username="'.$username.'" to_username="'.$user[0]['user'].'">Commentar</button>
                                    </div>
                                        <div class="errors-reply"></div>
                                </div>
                            </div>';
                    }

                    echo '

                </div>
            </div>';
    }

    function footer () {
        echo '<!-- Footer -->
                <div class="login-modal">
                    <div class="wrapper-login-modal">
                        <div class="header-login-modal">
                            <p>Iniciar sesión</p>
                            <i class="fa fa-times close-login"></i>
                            <hr>
                            
                        </div>
                        <div class="body-login-modal">
                            <input type="email" id="emailLogin" placeholder="Usuario">
                            <div class="password">
                                <input type="password" id="passwordLogin" placeholder="Contraseña">
                                <i class="fa fa-lock" id="lockLogin"></i>
                            </div>
                        </div>
                        <br/>
                            <div class="errors-login">
                            </div>

                            <div class="sending">
                                <i class="fa-solid fa-spinner"></i>
                                <p>Login...</p>
                            </div>
                        <div class="footer-login-modal">
                            <p>¿Aun no tienes cuenta? <span class="register" href="">Registrarse</span></p>
                            <button id="btnLogin">Iniciar sesión</button>
                        </div>
                    </div>
                </div>

                <div class="login-register">
                    <div class="wrapper-login-modal">
                        <div class="header-login-modal">
                            <p>Registrarse</p>
                            <i class="fa fa-times close-register"></i>
                            <hr>
                            
                        </div>
                        <div class="body-login-modal">

                            <div class="input-form">
                                <label for="name">Nombre: </label>
                                <input type="text" id="name" placeholder="Nombre">
                            </div>

                            <div class="input-form">
                                <label for="last_name">Apellidos: </label>
                                <input type="text" id="last_name" placeholder="Apellidos">
                            </div>

                            <div class="input-form">
                                <label for="phone">Teléfono: </label>
                                <input type="text" id="phone" placeholder="Teléfono">
                            </div>

                            <div class="input-form">
                                <label for="email">Usuario: </label>
                                <input type="email" id="email" placeholder="Usuario">
                            </div>

                            <div class="input-form">
                                <label for="password">Contraseña: </label>
                                <div class="password">
                                    <input type="password" id="password" placeholder="Contraseña">
                                    <i class="fa fa-lock" id="lockRegister"></i>
                                </div>
                            </div>

                            <div class="errors-login-register">
                            </div>

                            <div class="sending2">
                                <i class="fa-solid fa-spinner"></i>
                                <p>Enviando...</p>
                            </div>
                        </div>
                        <div class="footer-login-modal">
                            <p>¿Ya tienes cuenta? <span class="loginRegister">Iniciar sesión</span></p>
                            <button id="btnRegister">Registrarse</button>
                        </div>
                    </div>
                </div>

              <footer>
                <div class="wrapper-footer">
                  <!-- footer top -->
                  <div class="footer-top">
                    <div class="wrapper-footer-top">
                      <div class="wrapper-social">
                        <ul>
                          <li><a href="https://www.facebook.com/profile.php?id=100057629672564" title="Visitanos en facebook" target="_blank" rel="noopener" title=""><i class="fa-brands fa-facebook"></i><p>Vistanos en facebook</p></a></li>
                          <li><a href="#" title=""><i class="fa-brands fa-instagram"></i><p>Vistanos en instagram</p></a></li>
                          <li><a href="#" title=""><i class="fa-brands fa-youtube"></i><p>Visitanos en youtube</p></a></li>
                          <li><a href="#" title=""><i class="fa-brands fa-tiktok"></i><p>Visitanos en tiktok</p></a></li>
                        </ul>
                      </div>

                      <div class="wrapper-navigation">
                        <ul>
                          <li><a href="'. $this->routeFrontend .'" title="Hawaiin frogs" title="">Inicio</a></li>
                          <li><a href="'. $this->routeFrontend .'productos" title="">Productos</a></li>
                          <li><a href="'. $this->routeFrontend .'blog" title="">Blog</a></li>
                          <li><a href="'. $this->routeFrontend .'videos" title="">Videos</a></li>
                          <li><a href="'. $this->routeFrontend .'contacto" title="">Contacto</a></li>
                        </ul>
                      </div>
                    </div>
                  </div>

                  <!-- footer bottom -->
                  <div class="footer-bottom">
                    <div class="wrapper-footer-bottom">
                      <div class="footer-bottom-left">
                        <p>&copy; 2023, Hawaiin Frogs</p>
                      </div>
                      <div class="footer-bottom-right">

                      </div>
                    </div>
                  </div>
                </div>
              </footer>
        
                <div class="whatsapp-message">
                    <a href="https://api.whatsapp.com/send?phone=+526561459827&amp;text=Hola que tal, quisiera mas información sobre su servicio porfavor." title="Envianos tu whatsapp" target="_blank" rel="noopener">
                        <i class="fab fa-whatsapp"></i>
                    </a>
                </div>

              <div class="go-up">
                <i class="fa-solid fa-angles-up"></i>
                <i class="fa-solid fa-angles-up"></i>
              </div>
           

 <!-- import js files -->
                <script src="https://www.google.com/recaptcha/api.js?render=6LdnUPwmAAAAACNDs8BsBd6uuFKxd-bAAPuzTkMy"></script>
                <script src="'.$this->routeFrontend.'node_modules/sweetalert2/dist/sweetalert2.all.min.js"></script>
                <script src="'.$this->routeFrontend.'public/js/helpers/validations.js"></script>
                <script src="'.$this->routeFrontend.'public/js/helpers/helpers.js"></script>
                <script src="'.$this->routeFrontend.'public/js/helpers/object-fit-videos.js" type="module"></script>
                <script src="'.$this->routeFrontend.'public/js/main.js" type="module"></script>
                <!-- <script src="public/js/helpers/banner-video.js"></script> -->
  
            </body>
            </html>';
    }
}
EOF

# Queries.php
cat > "$project_name/core/class/Queries.php" << 'EOF'
<?php
class Queries {
	//--- QUERY SELECT ->  table | where item | where value | value for order | ASC/DESC | initial | final
	public static function select ( $table, $item = null, $value = null, $order = null, $mode = null, $initial = null, $stop = null ) {
		// echo "Table: " . $table . "<br>". "Item: " . $item . "<br>". "Value: " . $value . "<br>" . "Order: " . $order . "<br>" . "Mode: " . $mode . "<br>" . "Initial: " . $initial . "<br>" . "Stop: " . $stop;
        $conn = Connection::connect();
		$statement = null;

        try {
            if ( $item == null && $stop == null && $order == null ) {
                // echo "<h1>Query 1</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table" );
            }
            elseif ( $item == null && $stop == null && $order != null ) {
                // return $order;
                // echo "<h1>Query 2</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table ORDER BY $order $mode" );
            }
            elseif ( $item == null && $stop != null && $order != null ) {
                // echo "<h1>Query 3</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table ORDER BY $order $mode LIMIT $initial, $stop" );
            }
            elseif ( $item != null && $stop == null && $order == null ) {
                // echo "<h1>Query 4</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table WHERE $item = :$item" );
                $statement->bindParam( ":" . $item, $value, PDO::PARAM_STR );
            }
            elseif ( $item != null && $stop == null && $order != null ) {
                // echo "<h1>Query 5</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table WHERE $item = :$item ORDER BY $order $mode" );
                $statement->bindParam( ":" . $item, $value, PDO::PARAM_STR );
            }
            elseif ( $item != null && $stop != null && $order != null ) {
                // echo "<h1>Query 6</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table WHERE $item = :$item ORDER BY $order $mode LIMIT $initial, $stop" );
                $statement->bindParam( ":" . $item, $value, PDO::PARAM_STR );
            }
            else if ( $item == null && $order == null && $mode != null ) {
                // echo "<h1>Query 7</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table ORDER BY RAND() LIMIT $stop" );
            }
            else if ( $item != null && $order == null && $mode != null ) {
                // echo "<h1>Query 8</h1>";
                $statement = $conn->prepare( "SELECT * FROM $table WHERE $item = :$item ORDER BY RAND() LIMIT $stop" );
                $statement->bindParam( ':' . $item, $value );
            }

            $statement->execute();
            $result = $statement->fetchAll(PDO::FETCH_ASSOC);
            return $result;

        } finally {
            $statement = null;
            $conn = null;
        }
	}

	//--- Query for get une field
	public static function selectUnique( $table, $field, $item, $value ) {
        $conn = Connection::connect();
        $statement = null;

        try {
            $statement = $conn->prepare( "SELECT $field FROM $table WHERE $item = :$item" );
            $statement->bindParam( ":" . $item, $value, PDO::PARAM_STR );
            $statement->execute();
            $result = $statement->fetch(PDO::FETCH_ASSOC);
            return $result;
        } finally {
            $statement = null;
            $conn = null;
        }
	}

	//--- Query for get une field
	public static function mdlSelectTwoFields( $table, $field1, $field2, $item1, $item2, $value1, $value2 ) {
        $conn = Connection::connect();
        $statement = null;

        try {
            $statement = $conn->prepare( "SELECT $field1, $field2 FROM $table WHERE $item1 = :$item1 && $item2 = :$item2" );
            $statement->bindParam( ":" . $item1, $value1, PDO::PARAM_STR );
            $statement->bindParam( ":" . $item2, $value2, PDO::PARAM_STR );
            $statement->execute();
            $result = $statement->fetchAll(PDO::FETCH_ASSOC);
            return $result;
        } finally {
            $statement = null;
            $conn = null;
        }
	}

	//--- Query for search
	public static function search ( $table, $search, $order, $mode, $initial, $stop ) {
        $conn = Connection::connect();
        $statement = null;

        try {
            $statement = $conn->prepare( "SELECT * FROM $table WHERE name LIKE '%$search%' OR description LIKE '%$search%' OR attributes LIKE '%$search%' ORDER BY $order $mode" );
            $statement->execute();
            $result = $statement->fetchAll( PDO::FETCH_ASSOC );
            return $result;
        } finally {
            $statement = null;
            $conn = null;
        }
	}

    //--- Insert data
    public static function insert( $table, $arr_data = [] ) {
        $value_db = null;
        $value_placeholder = null;

        $keys = array_keys( $arr_data );

        for ($i=0; $i<count( $arr_data ); $i++) {
            if ( $i === ( count( $arr_data ) - 1 ) ) {
                $value_db .= $keys[$i];
                $value_placeholder .= ':'.$keys[$i];
            }
            else {
                $value_db .= $keys[$i].', ';
                $value_placeholder .= ':'.$keys[$i].', ';
            }
        }

        $conn = Connection::connect();
        $statement = null;

        try {
            $statement = $conn->prepare("
                INSERT INTO $table ($value_db)
                VALUES ($value_placeholder)
            ");

            for ($i=0; $i<count( $arr_data ); $i++) {
                $statement->bindParam(':'.$keys[$i], $arr_data[$keys[$i]], PDO::PARAM_STR);
            }

            if ( $statement->execute() ) return ['res'=>'success', 'msj'=> 'Save success'];
            else return (object) ['res'=>'error', 'msj'=> 'Server: Fail to get data'];

        } finally {
            $statement = null;
            $conn = null;
        }
    }

    //--- Update data
    public static function update( $table, $arr_data = [], $arr_cond = [], $cond = 'and' ) {
        $action_value = null;
        $action_cond = null;

        $keys_data = array_keys( $arr_data );
        $keys_cond = array_keys( $arr_cond );

        for ($i=0; $i<count( $arr_data ); $i++) {
            if ( $i === ( count( $arr_data ) - 1 ) ) {
                $action_value .= $keys_data[$i]. ' = ' . ':'.$keys_data[$i];
            }
            else {
                $action_value .= $keys_data[$i]. ' = ' . ':'.$keys_data[$i].', ';
            }
        }

        for ($i=0; $i<count( $arr_cond ); $i++) {
            $where = $keys_cond[$i];
            if ( $i === ( count( $arr_cond ) - 1 ) ) {
                if ($where === 'register_date' || $where === 'date')
                    $action_cond .= "DATE_FORMAT(".$keys_cond[$i].", '%Y-%m-%d')". " = " . ":".$keys_cond[$i];
                else
                    $action_cond .= $keys_cond[$i]. ' = ' . ':'.$keys_cond[$i];
            }
            else {
                if ($where === 'register_date' || $where === 'date')
                    $action_cond .= "DATE_FORMAT(".$keys_cond[$i].", '%Y-%m-%d')". " = " . ":".$keys_cond[$i].' '.$cond.' ';
                else
                    $action_cond .= $keys_cond[$i]. ' = ' . ':'.$keys_cond[$i].' '.$cond.' ';
            }
        }

        $conn = Connection::connect();
        $statement = null;

        try {
            $statement = $conn->prepare("
                UPDATE $table
                SET $action_value
                WHERE $action_cond
            ");

            for ($i=0; $i<count( $arr_data ); $i++) {
                $statement->bindParam(':'.$keys_data[$i], $arr_data[$keys_data[$i]], PDO::PARAM_STR);
            }

            for ($i=0; $i<count( $arr_cond ); $i++) {
                $statement->bindParam(':'.$keys_cond[$i], $arr_cond[$keys_cond[$i]], PDO::PARAM_STR);
            }

            if ( $statement->execute() ) return ['res'=>'success', 'msj'=> 'Update success'];
            else return (object) ['res'=>'error', 'msj'=> 'Server: Fail to update data'];
        } finally {
            $statement = null;
            $conn = null;
        }
    }


    //--- Delete data
    public static function delete( $table, $arr_data = [], $cond = 'and' ) {
        $action_value = null;
        $keys = array_keys( $arr_data );

        for ($i=0; $i<count( $arr_data ); $i++) {
            if ( $i === ( count( $arr_data ) - 1 ) ) {
                $action_value .= $keys[$i]. ' = ' . ':'.$keys[$i];
            }
            else {
                $action_value .= $keys[$i]. ' = ' . ':'.$keys[$i].' '.$cond.' ';
            }
        }

        $conn = Connection::connect();
        $statement = null;

        try {
            $statement = $conn->prepare("
                DELETE FROM $table
                WHERE $action_value
            ");

            for ($i=0; $i<count( $arr_data ); $i++) {
                $statement->bindParam(':'.$keys[$i], $arr_data[$keys[$i]], PDO::PARAM_STR);
            }

            if ( $statement->execute() ) return ['res'=>'success', 'msj'=> 'Delete success'];
            else return (object) ['res'=>'error', 'msj'=> 'Server: Fail to get data'];
        } finally {
            $statement = null;
            $conn = null;
        }
    }
}
EOF

# Routes.php
cat > "$project_name/core/class/Routes.php" << 'EOF'
<?php
class Routes extends Layout {
    //=========== CONSTRUCT
    function __construct( $lang ) {
        $this->lang = $lang;
    }

    function getRouteDashboard () {
        if ( $this->getLang() == 'es' ) {
            return 'https://localhost/projects/hawaiin_frogs/dashboard-sales/';
        } else if ( $this->getLang() == 'en' ) {
            return 'https://localhost/projects/hawaiin_frogs/dashboard-sales/';
        }
    }

    function getRouteBackend () {
        if ( $this->getLang() == 'es' ) {
            return 'https://localhost/projects/hawaiin_frogs/admon-hawaiin-frogs/';
        } else if ( $this->getLang() == 'en' ) {
            return 'https://ruta_english.com/admon';
        }
    }

    function getRouteFrontend () {
        if ( $this->getLang() == 'es' ) {
            return 'https://localhost/projects/hawaiin_frogs/';
        } else if ( $this->getLang() == 'en' ) {
            return 'https://ruta_english.com';
        }
    }
}
EOF

# Thumb.php
cat > "$project_name/core/class/Thumb.php" << 'EOF'
<?php
class Thumb {
	private $image;
	private $type;
	private $mime;
	private $width;
	private $height;

	//---Método de leer la imagen
	public function loadImage($name) {
        // return var_dump($name);
		//---Tomar las dimensiones de la imagen
		$info = getimagesize($name);

		$this->width = $info[0];
		$this->height = $info[1];
		$this->type = $info[2];
		$this->mime = $info['mime'];

		//---Dependiendo del tipo de imagen crear una nueva imagen
		switch($this->type){
			case IMAGETYPE_JPEG:
				$this->image = imagecreatefromjpeg($name);
			break;

			case IMAGETYPE_GIF:
				$this->image = imagecreatefromgif($name);
			break;

			case IMAGETYPE_PNG:
				$this->image = imagecreatefrompng($name);
			break;

			default:
				trigger_error('No se puede crear un thumbnail con el tipo de imagen especificada', E_USER_ERROR);
		}
	}

	//---Método de guardar la imagen
	public function save($name, $quality = 100, $type = false) {
		//---Si no se ha enviado un formato escoger el original de la imagen
		$type = ($type) ? $type : $this->type;

		//---Guardar la imagen en el tipo de archivo correcto
		switch($type){
			case IMAGETYPE_JPEG:
				imagejpeg($this->image, $name . image_type_to_extension($type), $quality);
			break;

			case IMAGETYPE_GIF:
				imagegif($this->image, $name . image_type_to_extension($type));
			break;

			case IMAGETYPE_PNG:
				$pngquality = floor($quality / 100 * 9);
				imagepng($this->image, $name . image_type_to_extension($type), $pngquality);
			break;

			default:
				trigger_error('No se ha especificado un formato de imagen correcto', E_USER_ERROR);
		}
	}

	//---Método de mostrar la imagen sin guardarla
	public function show($type = false, $base64 = false) {
		//---Si no se ha enviado un formato escoger el original de la imagen
		$type = ($type) ? $type : $this->type;
		if($base64) ob_start();

		//---Mostrar la imagen dependiendo del tipo de archivo
		switch($type){
			case IMAGETYPE_JPEG:
				imagejpeg($this->image);
			break;

			case IMAGETYPE_GIF:
				imagegif($this->image);
			break;

			case IMAGETYPE_PNG:
				$this->prepareImage($this->image);
				imagepng($this->image);
			break;

			default:
				trigger_error('No se ha especificado un formato de imagen correcto', E_USER_ERROR);
				exit;
		}

		if($base64) {
			$data = ob_get_contents();
			ob_end_clean ();
			return 'data:' . $this->mime . ';base64,' . base64_encode($data);
		}
	}

	//---Método de redimensionar la imagen sin deformarla
	public function resize($value, $prop){
		//---Determinar la propiedad a redimensionar y la propiedad opuesta
		$prop_value = ($prop == 'width') ? $this->width : $this->height;
		$prop_versus = ($prop == 'width') ? $this->height : $this->width;

		//---Determinar el valor opuesto a la propiedad a redimensionar
		$pcent = $value / $prop_value;
		$value_versus = $prop_versus * $pcent;

		//---Crear la imagen dependiendo de la propiedad a variar
		$image = ($prop == 'width') ? imagecreatetruecolor($value, $value_versus) : imagecreatetruecolor($value_versus, $value);	

		//---Tratar la imagen
		if($this->type == IMAGETYPE_GIF || $this->type == IMAGETYPE_PNG) $this->prepareImage($image);	

		//---Hacer una copia de la imagen dependiendo de la propiedad a variar
		switch($prop){
			case 'width':
				imagecopyresampled($image, $this->image, 0, 0, 0, 0, $value, $value_versus, $this->width, $this->height);
			break;

			default:
				imagecopyresampled($image, $this->image, 0, 0, 0, 0, $value_versus, $value, $this->width, $this->height);
		}

		//---Actualizar la imagen y sus dimensiones
		$this->width = imagesx($image);
		$this->height = imagesy($image);
		$this->image = $image;
	}

	//---Método de extraer una sección de la imagen sin deformarla
	public function crop($cwidth, $cheight, $pos = 'center') {
		$pcent = min($this->width / $cwidth, $this->height / $cheight);
		$bigw = (int) ($pcent * $cwidth);
		$bigh = (int) ($pcent * $cheight);

		//---Crear la imagen
		$image = imagecreatetruecolor($cwidth, $cheight);

		//---Tratar la imagen
		if($this->type == IMAGETYPE_GIF || $this->type == IMAGETYPE_PNG) $this->prepareImage($image);

		//---Dependiendo de la posición copiar
		switch($pos){
			case 'left':
				imagecopyresampled($image, $this->image, 0, 0, 0, abs(($this->height - $bigh) / 2), $cwidth, $cheight, $bigw, $bigh);
			break;

			case 'right':
				imagecopyresampled($image, $this->image, 0, 0, $this->width - $bigw, abs(($this->height - $bigh) / 2), $cwidth, $cheight, $bigw, $bigh);
			break;

			case 'top':
				imagecopyresampled($image, $this->image, 0, 0, abs(($this->width - $bigw) / 2), 0, $cwidth, $cheight, $bigw, $bigh);
			break;

			case 'bottom':
				imagecopyresampled($image, $this->image, 0, 0, abs(($this->width - $bigw) / 2), $this->height - $bigh, $cwidth, $cheight, $bigw, $bigh);
			break;

			default:
				imagecopyresampled($image, $this->image, 0, 0, abs(($bigw - $this->width) / 2), abs(($bigh - $this->height) / 2), $cwidth, $cheight, $bigw, $bigh);
		}

		$this->width = $cwidth;
		$this->height = $cheight;
		$this->image = $image;
	}

	//---Método privado de tratar las imágenes antes de mostrarlas
	private function prepareImage($image){
		//---Dependiendo del tipo de imagen
		switch($this->type){
			case IMAGETYPE_GIF:
				$background = imagecolorallocate($image, 0, 0, 0);
				imagecolortransparent($image, $background);
			break;

			case IMAGETYPE_PNG:
				imagealphablending($image, FALSE);
				imagesavealpha($image, TRUE);
			break;
		}
	}
}
EOF

# Validators.php
cat > "$project_name/core/class/Validators.php" << 'EOF'
<?php
class Validators  {
    //--- Validate empty
    public static function validateEmpty( $value ) {
        if ( empty( $value ) ) return false;
        if ( strlen( $value ) < 8 ) return false;
        return true;
    }

    //--- Validate email
    public static function validateEmail( $email ) {
        if ( !preg_match( '/^[^0-9][a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[@][a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[.][a-zA-Z]{2,4}$/', $email )) return false;
        return true;
    }

    //---Encrypted passwoord
    public static function encryptedPassword( $pass ) {
        return crypt( $pass, '$2a$07$asxx54ahjppf45sd87a5a4dDDGsystemdev$' );
    }

    //--- Validate string
    public static function validateParagraph( $paragraph ) {
        if ( !preg_match( '/^[-a-zA-ZñÑáéíóúÁÉÍÓÚ0-9_\/:&;\n.,\s]*$/', $paragraph ) ) return false;
        return true;
    }

    //--- Validate number
    public static function validateNumber( $value ) {
        if ( !preg_match("/^[0-9]+(?:\.[0-9]+)?$/", $value) ) return false;
        return true;
    }

    //--- Validate array or object
    public static function validateArray ( $array ) {
        if ( count( $array ) > 0 ) return true;
        return false;
    }
}
EOF

# Init
cat > "$project_name/core/init.php" << 'EOF'
<?php
declare(strict_types = 1);

$GLOBALS['config'] = [
    'mysql' => [
        'host'=>    'localhost',
        'usr'=>     'root',
        'psw'=>     '',
        'dbname'=>  'hawwaiin_frogs'
    ],
    'lang' => 'es',
    'cookie' => [
        'name' => 'name_cookie',
        'expire' => 'expire_cookie'
    ]
];

// Load automaticaly class 
spl_autoload_register(function($class){
    $paths = [
        'core/class/',      // base class
        'app/controller/',  // controllers
        'app/models',       // models
        'core/libs'         // libraries
    ];

    foreach ($paths as $path) {
        $file = __DIR__.'/../'.$path.$class.'.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }

    // Register error_log if doesn't exists
    error_log("Class Not Found: $class");
});

new Config(true, 'America/Chihuahua');
//Connection::getInstance();
EOF

# index
cat > "$project_name/index.php" << 'EOF'
<?php
require __DIR__.'/core/init.php';

//--- Enable SESSION and set TIMEZONE
new Config( treu, 'America/Chihuahua' );

$lang = $GLOBALS['config']['lang'] ?? 'es';
$routes = new Routes( $lang );
$thumb = new Thumb();

//--- Config class Layout to use
$layout = new Layout( $lang, [ $routes->getRouteFrontend(), $routes->getRouteBackend] );

//--- Include file router
include __DIR__.'/app/router.php';
?>
EOF

#--- Router
cat > "$project_name/app/router.php" << 'EOF'
<?php
class Router {
    // Routes config
    private static $routes [
        // Routes simples (lev1)
        '1' => [
            'name-simple-page' => [
                'file' => './app/views/pages/name-simple-page.php',
                'db_check' => false
            ],
            // Add more routes here...
        ],

        // Routes to categories (lev2)
        '2' => [
            'name-catergory-page' => [
                'file' => './app/views/pages/name-category-page.php',
                'db_check' => [
                    'table' => 'table-category'
                    'field' => 'url'
                ]
            ],
            // Add more routes here...
        ],

        // Routes to single items (lev3)
        '3' => [
            'name-individual-page' => [
                'file' => './app/views/pages/name-individual-page.php',
                'db_check' => [
                    'table' => ['table-individual', 'table-category'],
                    'field' => ['url1', 'url2']
                ]
            ],
            // Add more routes here...
        ]
    ];

    public static funcion handleRequest() {
        // Showing homepage
        if (!isset($_GET[ 'route' ])) {
            require './app/views/pages/index.view.php';
            return;
        }

        // Routes processing
        $route = explode('/', $_GET['route']);
        $route = array_filter($route); // Delete empty elements
        $level = count($route);

        // Routing 
        if (!isset(self::$routes[$level])) {
            self::show404();
            return;
        }

        $main_route = strtolower($route[0]);

        if (!isset(self::$routes[$level][$main_route])) {
            self::show404();
            return;
        }

        $route_config = self::$routes[$level][$main_route];

        // Verify db if is necesary
        if ($route_config['db_check'] !== false) {
            if (!self::checkDatabase($route, $route_config['db_check'])) {
                self::show404();
                return;
            }
        }

        require $route_config['file'];
    }

    private static function checkDatabase($route, $config) {
        if ($route == 2) {
            $result = Queries::select($config['table'], $config['field'], $route[1]);
            return count($result) > 0;
        }
        else if ($route === 3){
            $result = Queries::select($config['table'][0], $config['field'][0], $route[2]);
            $result = Queries::select($config['table'][1], $config['field'][1], $route[1]);
            $return (count($result) > 0 && count($result2) > 0);
        }
        return false;
    }

    private static function show404() {
        header('HTTP/1.0 404 Not Found');
        require './app/views/pages/404.php';
    }

}

// Use class
Router()handleRequest();
?>
EOF

#--- AJAX
cat > "$project_name/app/ajax/example.ajax.php" << 'EOF'
<?php
require __DIR__.'/../../core/init.php';

class ExampleAPI {
    private $controller;

    public function __construct() {
        // $this->mailer = new PHPMailer();
        $this->controller = new CommentsController();
        $this->validateRequest();
    }

    public function validateRequest() {
        // Verify ajax request
        if (empty($_SERVER['HTTP_X_REQUESTED_WITH'])) || strtolower($_SEVER['HTTP_X_REQUESTED_WITH']) != 'xmlhttprequest' {
            http_response_code(403);
            exit('Acceso denieg');
        }

        // Only accept POST
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            exit('Request not permit');
        }

        header('Content-Type: application/json');
    }

    public function handle() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);

            if (isset($_POST['create_data'])) {
                $this->handleCreateData($_POST['create_data']);
            }
            elseif (isset($_POST['save_data'])) {
                $this->handleUpdateData($_POST['save_data']);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['ERROR' => $e->getMessage()]);
        }
    }

    private function handleCreateData($data) {
        $result = $this->controller->createData(
            json_decode($data, true);
        );
        echo json_encode($result);
    }

    private function handleUpdateData($data) {
        $result = $this->controller->updateData(
            json_decode($data, true);
        );
        echo json_encode($result);
    }
}

(new ExampleAPI())->handle();
EOF

#--- CONTROLLER
cat > "$project_name/app/ajax/example.ajax.php" << 'EOF'
<?php
class ExampleController {
    public function createData(array $data) {
        // validations
        if (!true) {
            throw new InvalidArgumentExeption('Datos incompletos');
        }

        // Sanitization
        $clean_data = [
            'id' => (int)$data['id']
        ]

        // Send email if is needed
        /* if(isset($data['user']) && isset($data['to_user']) && isset($data['url'])) { */
            /* $this->sendMentionEmail( */
            /*     $data['user'], */
            /*     $data['to_user'], */
            /*     $clean_data['comment'], */
            /*     $data['url'], */
            /*     $clean_data['id_product'] */
            /* ); */
        /* } */

        // Operation with db
        return Queries::insert('comments', $clean_data);
    }

    public function updateData(array $data) {
        // Sanitization
        $clean_data = [
            'id' => (int)$data['id']
        ]

        $model = new CommentsModel();
        $existing = $model->getData($clean_data);

        return $existing
            ? Queries::update('likes', $clean_data, ['id' => $existing['id']])
            : Queries::insert('likes', $clean_data);
    }

    private function sendMentionEmail( $from, $to, $comment, $baseUrl, $productId ) {
        // PHPMailer
    }
}
EOF

#--- MODEL
cat > "$project_name/app/ajax/example.ajax.php" << 'EOF'
<?php
class CommentsModel {
    public function function getLike(array $data) {
        $conn = Connection::connect();
        $stmt = $conn->prepare("
            SELECT * FROM likes 
            WHERE id_user = :id_user AND id_product = :id_product 
            LIMIT 1
        ");

        $stmt->bindValue(':id_user', $data['id_user'], PDO::PARAM_INT);
        $stmt->bindValue(':id_product', $data['id_product'], PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}
EOF

# views
# 404
cat > "$project_name/app/views/pages/404.php" << 'EOF'
<?php
EOF

# index
cat > "$project_name/app/views/pages/index.view.php" << 'EOF'
<?php
EOF

# /public/css
# style.scss
cat > "$project_name/public/css/style.scss" << 'EOF'
@import url('https://fonts.googleapis.com/css2?family=Lato:wght@400;700&family=Poppins:wght@400;500;600;700&display=swap');
@font-face {
  font-family: 'Lexend Deca';
  font-style: normal;
  font-weight: 400;
  src:url("../webfonts/LexendDeca-VariableFont_wght.ttf");
}

* {
    padding: 0;
    margin:0;
    box-sizing: border-box;
}

a {
    text-decoration: none;
}

li {
    list-style: none;
}

:root {
    --font1: 'Poppins', sans-serif;
    --font2: 'Lato', sans-serif;

    --light:#F9F9F9;
    --light2:#d7d7d7;
    --blue:#3C91E6;
    --light-blue: #CFE8FF;
    --grey: #eee;
    --dark-grey: #AAAAAA;
    --dark: #342E37;
    --red:#DB504A;
    --yellow:#FFCE26;
    --yellow-light:#FFF2C6;
    --orange:#FD7238;
    --light-orange:#FFE0D3;

    --z1: 1;
    --z2: 2;
    --z3: 3;
    --z4: 4;
    --z5: 5;
    --z6: 6;
    --z7: 7;
    --z8: 8;
    --z9: 9;
    --z10: 10;
    --z11: 11;
    --z12: 12;
}

html {
    overflow: hidden;
}

body.dark {
    --light: #0C0C1E;
    --grey: #060714;
    --dark: #FBFBFB;
}

body {
    background:var(--grey);
    overflow-x: hidden;
}

.d-block { display: block }
.d-none { display: none }

.btn-table {
    position:relative;
    font-size: .8rem;
    padding: 6px 16px;
    color: var(--light);
    border-radius: 20px;
    font-weight: 700;
    cursor:pointer;
    border: none;
    transition:.3s ease;

    &.complete {
        background: var(--blue);
    }
    &.pending {
        background: var(--orange);
    }
    &.process {
        background: var(--yellow);
    }
    &.danger {
        background: var(--red);
    }

    span {
        position:absolute;
        content:'';
        font-family: var(--font1);
        font-size: .7rem;
        background:var(--light2);
        color:var(--dark);
        top:120%;
        right:10px;
        padding:5px;
        border-radius:15px;
        z-index:var(--z2);
        opacity: 0;
        visibility: hidden;
        transition: .2s ease;

        &:before {
            position:absolute;
            content:'';
            background:var(--light2);
            top:-4px;
            right:10px;
            width: 10px;
            height: 10px;
            transform:rotate(45deg);
        }
    }

    &:hover {
        span {
            opacity: 1;
            visibility: visible;
        }
    }
}

@keyframes spinner {
    0% {
        transform:rotate(0deg);
    }
    100% {
        transform:rotate(360deg);
    }
}

main {
    &#customers {

        .sending {
            position:absolute;
            top:120px;
            right:50px;
            display: none;
            align-items: center;

            i {
                position:abolute;
                animation: spinner 1s linear infinite;
            }

            p {
                margin-left:10px;
            }
        }
    }
}

/**
 * Import stylesheets
 */
@import 'scss/_header.scss', 'scss/loader';
EOF

# main.js
cat > "$project_name/public/js/main.js" << 'EOF'
import {loader} from './helpers/generals.js';

import {
    mode,
    validateTheme,
    toggleSidebar,
    showUserInfo,
    logout
} from './helpers/navbar.js';

// Imports al js from /helpers/

//import { sidebar } from './helpers/sidebar.js';

/** service worker */
if ('serviceWorker' in navigator) {
	window.addEventListener('load', function () {
		navigator.serviceWorker.register('/sw.js')
			.then(function () {
				// console.log('ServiceWorker registered!');
			})
			.catch(function (err) {
				// console.log('ServiceWorker failed :(', err);
			});
	});
}

// Call all functions
login();
loader();
sidebar();

mode();
validateTheme();
toggleSidebar();
showUserInfo();
logout();
EOF

# generals.js
cat > "$project_name/public/js/helpers/generals.js" << 'EOF'
export const loader = () => {
    window.addEventListener('load', (e) => {
        document.querySelector('.loader').style.display = 'none';
    })
}
EOF

# helpers.js
cat > "$project_name/public/js/helpers/helpers.js" << 'EOF'
//--- Catitalize word
const capitalizeFirstLetter = (str) => {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

//--- Clean text
let cleanText = ( text ) => {
    var text = text.toLowerCase();
    text = text.replace( /[á]/, 'a' );
    text = text.replace( /[é]/, 'e' );
    text = text.replace( /[í]/, 'i' );
    text = text.replace( /[ó]/, 'o' );
    text = text.replace( /[ú]/, 'u' );
    text = text.replace( /[ñ]/, 'n' );
    text = text.replace( / /g, '-' );
    return text;
}

//--- Get data from petition 
const getDataByFetch = async ( url, name_data, data, type = 'json' ) => { 
    let fd = new FormData();
    fd.append( name_data, data );

    const res = await fetch( url, {method: 'POST',body: fd} );
    if ( type === 'json' )
        return await res.json();
    else if ( type === 'text' ) 
        return await res.text();
}
EOF

# login.js
cat > "$project_name/public/js/helpers/login.js" << 'EOF'
export const login = () => {
    if ( document.querySelector('#loginForm') == null ) return;

    //---Show / hide password
    let changer = 0;
    document.querySelector('#showHide').addEventListener('click', e => {
        if ( changer == 0 ) {
            document.querySelector('#password').type = 'text';
            e.currentTarget.classList.toggle('bxs-lock-open');
            e.currentTarget.classList.toggle('bxs-lock');
            changer++;
        } else if  ( changer == 1 ) {
            document.querySelector('#password').type = 'password';
            e.currentTarget.classList.toggle('bxs-lock-open');
            e.currentTarget.classList.toggle('bxs-lock');
            changer--;
        }
    })

    //--- Verify access data in localStorage
    const checkbox_remember_pass = document.querySelector('#rememberPassword');
    const vefifyAccessSaved = () => {
        if ( localStorage.getItem( 'access_dashboar_hawwaiin' ) ) {
            const data = JSON.parse( localStorage.getItem( 'access_dashboar_hawwaiin' ) );

            if ( data.user_name !== '' && data.user_pas !== '' ) {
                checkbox_remember_pass.checked =true;
                document.querySelector('input[name=email]').value = data.user_name;
                document.querySelector('input[name=password]').value = data.user_pas;
            }
        }
    }
    vefifyAccessSaved();

    //--- Click button enter
    document.querySelector('#loginForm').addEventListener('submit', async e => {
        e.preventDefault();
        //--- Remenber password
        if ( checkbox_remember_pass.checked )  {
            const access_dashboar_hawwaiin = {
                user_name: document.querySelector('input[name="email"]').value,
                user_pas: document.querySelector('input[name="password"]').value,
            }
            localStorage.setItem('access_dashboar_hawwaiin',  JSON.stringify( access_dashboar_hawwaiin ) );
        } else {
            localStorage.removeItem('access_dashboar_hawwaiin');
        }
        let errors = document.querySelector('#errors');
        errors.innerHTML = '';
        let val_form = true;

        if ( !validateEmail(e.currentTarget.email.value) ) {
            errors.innerHTML += `<p>* Correo no valido</p`;
            errors.style.display = 'block';
            val_form = false;
        } else {
            errors.style.display = 'none';
            val_form = true;
        }

        if ( !validarPassword(e.currentTarget.password.value) ) {
            errors.innerHTML += `<p>* Contraseña min 8 catecteres, MAYUS, y caracteres epeciales</p`;
            errors.style.display = 'block';
            val_form = false;
        } else {
            errors.style.display = 'none';
            val_form = true;
        }

        if ( val_form ) {
            const url = localStorage.route_backend_hawwaiin + 'app/ajax/users.ajax.php';
            const data = {
                user: e.currentTarget.email.value,
                password: e.currentTarget.password.value
            }

            const res = await getDataByFetch( url, 'login', JSON.stringify( data ), 'json' );

            if ( res === 'success' ) 
                window.location.reload();

            else if ( res === 'fail_verification' ) {
                errors.innerHTML += `<p>Correo no verificado</p`;
                errors.style.display = 'block';
            }

            else if ( res ===  'fail_pws' )  {
                errors.innerHTML += `<p>Correo / Contraseña incorrectos</p`;
                errors.style.display = 'block';
            }

            else if ( res === 'not-exists' ) {
                errors.innerHTML += `<p>El correo no existe</p`;
                errors.style.display = 'block';
            }

            else if ( res === 'no-permissions' ) {
                errors.innerHTML += `<p>Sin permisos para acceder</p`;
                errors.style.display = 'block';
            }
        } 
    })
}
EOF

# navbar.js
cat > "$project_name/public/js/helpers/navbar.js" << 'EOF'
export const mode = () => {

    const reviewSizeWith = () => {
        if ( screen.width < 400 ) {
            document.querySelector('.nav-link').style.display = 'none';
            document.querySelector('#sidebar').classList.toggle('hide');
            document.querySelector('#hamburger').classList.add('bx-menu');
            document.querySelector('#hamburger').classList.remove('bxs-chevrons-left');
        } else { 
            document.querySelector('.nav-link').style.display = 'block'; 
            document.querySelector('#hamburger').classList.remove('bx-menu');
            document.querySelector('#hamburger').classList.add('bxs-chevrons-left');
        }
    }
    reviewSizeWith();

    window.addEventListener('resize', () => {
        reviewSizeWith();
    })

    const switch_mode = document.getElementById('switch-mode');

    if ( switch_mode == null ) return;

    switch_mode.addEventListener('click', ( e ) => {
        if ( e.currentTarget.checked ) {
            document.body.classList.add('dark');
            document.querySelector('.switch-mode').classList.add('actived');
            localStorage.setItem('dark_mode', true);
        } else  {
            document.body.classList.remove('dark');
            document.querySelector('.switch-mode').classList.remove('actived');
            localStorage.setItem('dark_mode', false);
        }
    });

}
EOF

# sidebar.js
cat > "$project_name/public/js/helpers/sidebar.js" << 'EOF'
export const sidebar = () => {
    const items_menu = document.querySelectorAll('.side-menu .side-menu-item');
    const submenu = document.querySelectorAll('.side-submenu');

    items_menu.forEach( ( item, i ) => {
        item.addEventListener('click', e => {
            // console.log( e.currentTarget.parentNode.querySelector('.side-submenu') );
            if ( e.currentTarget.parentNode.querySelector('.side-submenu') === null ) return;
            e.currentTarget.parentNode.querySelector('.side-submenu').classList.toggle('show-hide');
            // submenu[i].classList.toggle('show-hide');
        })
    })
}
EOF

# validations.js
cat > "$project_name/public/js/helpers/validations.js" << 'EOF'
//--- Validate paragraph
let validateParagraph = (value) => {
    const exp = /^[-a-zA-ZñÑáéíóúÁÉÍÓÚ0-9_/:&;/\n/g., ]*$/;
    if (exp.test(value)) return true;
    else return false;
}

//--- Validate lenghts
let validateLengths = ( valueMax, valueCurrent ) => {
    if ( valueCurrent <= valueMax ) return true;
    else return false;
}

//--- Validate number
let validateNumber = ( value ) => {
    // const exp = /^([ 0-9 ])*$/;
    const exp = /^\d+(\.\d{1,2})?$/;
    if ( !exp.test( value ) ) return false;
    else return true;
}

//--- Validate number
let validatePhone = ( value ) => {
    const exp = /^[0-9]+$/;
    if ( value !== '' ) {
        if ( !exp.test( value ) ) return false;
        else return  true;
    }
    else return true;
}

//--- Validate name
let validateName = ( value ) => {
    const exp = /^[a-zA-ZñÑáéíóúÁÉÍÓÚ, ]*$/;
    if ( !exp.test( value ) ) return false;
    else return true;
}

//--- Validate url
let validateUrl = ( value ) => {
    const exp = /^[-a-zA-Z0-9_:&;\ng.]*$/;
    if ( !exp.test( value ) ) return false;
    else return true;
}

//--- Validate arrayStrigify 
let validateArrayStringify = ( value ) => {
    const exp = /^\[[0-9]+,[0-9]+\]$/;
    if ( !exp.test( value ) ) return false;
    else return true;
}

//--- Validate Array
let validateArray = ( value ) => {
    if ( value.length > 0 ) return true;
    else  return false;
}

//--- Validate email
let validateEmail = (value) => {
    const exp = /^[-\w.%+]{1,64}@(?:[A-Z0-9-]{1,63}\.){1,125}[A-Z]{2,63}$/i;
    if ( value == '' || value == null ) {
        return false;
    } else if ( !exp.test( value ) ) {
        return false;
    } else {
        return true;
    }
}

//--- Validate password
let validarPassword = (value) => {
    if (value != "") {
        if (value.length >= 8) {
            var mayus = false,
                minus = false,
                num = false,
                char = false;

            for (let i = 0; i < value.length; i++) {
                if (
                    value.charCodeAt(i) >= 65 &&
                    value.charCodeAt(i) <= 90
                ) {
                    mayus = true;
                } else if (
                    value.charCodeAt(i) >= 97 &&
                    value.charCodeAt(i) <= 122
                ) {
                    minus = true;
                } else if (
                    value.charCodeAt(i) >= 48 &&
                    value.charCodeAt(i) <= 57
                ) {
                    num = true;
                } else {
                    char = true;
                }
            }

            if (
                mayus == false ||
                minus == false ||
                num == false ||
                char == false ) {
                return false;
            } else {
                return true;
            }
        } else {
            return false;
        }
    } else {
        return false;
    }
}

const validateForm = ( data, content_errors ) => {
    //  data = [
    //     name, value, type, empty,
    //  ]
    let res = [];
    content_errors.innerHTML = '';

    data.forEach(dt => {
        const { name, value, type, empty } = dt;

        if ( type === 'string' ) {
            if ( !empty && value === '' ) { 
                content_errors.innerHTML += `<p>*Debe agregar ${ name }</p>`;
                res.push(false); 
                return;
            }

            if ( !validateParagraph( value ) )  { 
                content_errors.innerHTML += `<p>*${ name } incorrecto</p>`; 
                res.push(false) }
            else { res.push(true) }
        }

        if ( type === 'email' ) {
            if ( !empty && value === '' ) { 
                content_errors.innerHTML += `<p>*Debe agregar ${ name }</p>`; 
                res.push(false); 
                return;
            }

            if ( !validateEmail( value ) )  { 
                content_errors.innerHTML += `<p>*${ name } incorrecto</p>`; 
                res.push(false) 
            }
            else { res.push(true) }
        }

        if ( type === 'number' ) {
            if ( !empty && value === '' ) { 
                content_errors.innerHTML += `<p>*Debe agregar ${ name }</p>`; 
                res.push('false'); 
                return;
            }

            if ( !validateNumber( value ) )  { 
                content_errors.innerHTML += `<p>*${ name } incorrecto</p>`; 
                res.push(false) 
            }
            else { res.push(true) }
        }

        if ( type === 'phone' ) {
            if ( !empty && value === '' ) { 
                content_errors.innerHTML += `<p>*Debe agregar ${ name }</p>`; 
                res.push('false'); 
                return;
            }

            if ( !validatePhone( value ) )  { 
                content_errors.innerHTML += `<p>*${ name } incorrecto</p>`; 
                res.push(false) 
            }
            else { res.push(true) }
        }

        if ( type === 'url' ) {
            if ( !empty && value === '' ) { 
                content_errors.innerHTML += `<p>*Debe agregar ${ name }</p>`; 
                res.push('false'); 
                return;
            }

            if ( !validateUrl( value ) )  { 
                content_errors.innerHTML += `<p>*${ name } incorrecto</p>`; 
                res.push(false) 
            }
            else { res.push(true) }
        }

        if ( type === 'arraystringify' ) {
            if ( !empty && value === '' ) { 
                content_errors.innerHTML += `<p>*Debe agregar ${ name }</p>`; 
                res.push('false'); 
                return;
            }

            if ( !validateArrayStringify( value ) )  { 
                content_errors.innerHTML += `<p>*${ name } incorrecto</p>`; 
                res.push(false) 
            }
            else { res.push(true) }
        }

        if ( type === 'array' ) {
            if ( !empty && !validateArray( value ) )  { 
                content_errors.innerHTML += `<p>*${ name } incorrecto</p>`; 
                res.push(false) 
            }
            else { res.push(true) }
        }

        if ( type == 'password' ) {
            if ( !empty || value !== '' ) {
                if (value != "") {
                    if (value.length >= 8) {
                        var mayus = false,
                            minus = false,
                            num = false,
                            char = false;

                        for (let i = 0; i < value.length; i++) {
                            if (
                                value.charCodeAt(i) >= 65 &&
                                value.charCodeAt(i) <= 90
                            ) {
                                mayus = true;
                            } else if (
                                value.charCodeAt(i) >= 97 &&
                                value.charCodeAt(i) <= 122
                            ) {
                                minus = true;
                            } else if (
                                value.charCodeAt(i) >= 48 &&
                                value.charCodeAt(i) <= 57
                            ) {
                                num = true;
                            } else {
                                char = true;
                            }
                        }

                        if (
                            mayus == false ||
                            minus == false ||
                            num == false ||
                            char == false ) {
                            content_errors.innerHTML += `<p>*${ name } Debe tener mayus, minus, numeros y caracteres especiales</p>`; 
                            res.push(false);
                        } else {
                            res.push(true);
                        }
                    } else {
                        content_errors.innerHTML += `<p>*${ name } Debe tener min 8 caracteres</p>`; 
                        res.push(false);
                    }
                } else {
                    content_errors.innerHTML += `<p>*Debe agreagr ${ name }</p>`; 
                    res.push(false);
                }
            } else { res.push(  true ) }
        }
    });
    const response  = res.every((item) => item === true)
    return response;
}
EOF

# .htaccess
cat > "$project_name/.htaccess" << 'EOF'
# | Cross-origin images |
<IfModule mod_setenvif.c>
    <IfModule mod_headers.c>
        <FilesMatch "\.(bmp|cur|gif|ico|jpe?g|png|svgz?|webp)$">
            SetEnvIf Origin ":" IS_CORS
            Header set Access-Control-Allow-Origin "*" env=IS_CORS
        </FilesMatch>
    </IfModule>
</IfModule>


# | Cross-origin |
Header set Access-Control-Allow-Origin "*"


# | Error 404 |
ErrorDocument 404 /404.php


# | Force IE to render pages |
<IfModule mod_headers.c>
    Header set X-UA-Compatible "IE=edge"
    <FilesMatch "\.(appcache|crx|css|eot|gif|htc|ico|jpe?g|js|m4a|m4v|manifest|mp4|oex|oga|ogg|ogv|otf|pdf|png|safariextz|svgz?|ttf|vcf|webapp|webm|webp|woff|xml|xpi)$">
        Header unset X-UA-Compatible
    </FilesMatch>
</IfModule>


# | UTF-8 Encoding |
AddDefaultCharset utf-8
# Force UTF-8 for certain file formats.
<IfModule mod_mime.c>
    AddCharset utf-8 .atom .css .js .json .rss .vtt .webapp .xml
</IfModule>


### --- NUEVA CONFIGURACIÓN DE SESIONES PHP (AGREGADA AQUÍ) --- ###
# <IfModule php_module>
    # php_value session.gc_maxlifetime 3600     # Sesiones expiran en 1 hora
    # php_value session.gc_probability 1        # 1% de probabilidad de limpieza
    # php_value session.gc_divisor 100          # Cada 100 peticiones
# </IfModule>
### --- FIN DE NUEVA CONFIGURACIÓN --- ###


# | Web performance |
<IfModule mod_deflate.c>
    <IfModule mod_setenvif.c>
        <IfModule mod_headers.c>
            SetEnvIfNoCase ^(Accept-EncodXng|X-cept-Encoding|X{15}|~{15}|-{15})$ ^((gzip|deflate)\s*,?\s*)+|[X~-]{4,13}$ HAVE_Accept-Encoding
            RequestHeader append Accept-Encoding "gzip,deflate" env=HAVE_Accept-Encoding
        </IfModule>
    </IfModule>

    <IfModule mod_filter.c>
        AddOutputFilterByType DEFLATE application/atom+xml \
                                      application/javascript \
                                      application/json \
                                      application/rss+xml \
                                      application/vnd.ms-fontobject \
                                      application/x-font-ttf \
                                      application/x-web-app-manifest+json \
                                      application/xhtml+xml \
                                      application/xml \
                                      font/opentype \
                                      image/svg+xml \
                                      image/x-icon \
                                      text/css \
                                      text/html \
                                      text/plain \
                                      text/x-component \
                                      text/xml
    </IfModule>
</IfModule>


# | Forcing HTTPS |
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</IfModule>


# | Cross-origin images |
<IfModule mod_rewrite.c>
    Options +FollowSymlinks
    Options +SymLinksIfOwnerMatch
    RewriteEngine On
    # RewriteBase /dashboard-sales/

    RewriteRule ^([-a-zA-Z0-9ñÑ_/]+)$ index.php?ruta=$1
</IfModule>
EOF

# manifest.json
cat > "$project_name/public/img/icons/manifest.json" << 'EOF'
{
    "name": "Hawaiian Frogs | Admin",
    "short_name": "HawaiianFrogs Admin",
    "description":"HAWAIIAN FROGS te ofrece fresas con crema, elotes, raspados, platillos como waffles, entre otros mas, visítanos | HAWAIIAN FROGS  ciudad juárez",
    "start_url": "https://hawaiianfrogs.com.mx/admon-hawaiin-frogs/",
    "theme_color": "#43b544",
    "background_color": "#09135A",
    "display": "standalone",
    "orientation":"portrait",
    "icons": [
        {
            "src": "/public/img/icons/android/android-icon-36x36.png",
            "sizes": "36x36",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-48x48.png",
            "sizes": "48x48",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-72x72.png",
            "sizes": "72x72",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-96x96.png",
            "sizes": "96x96",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-144x144.png",
            "sizes": "144x144",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-192x192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-512x512.png",
            "sizes": "512x512",
            "type": "image/png"
        }
    ]
}
EOF

# sw.js
cat > "$project_name/public/img/icons/manifest.json" << 'EOF'
self.addEventListener( 'fetch', event => {
  // console.log( event );
})
EOF

# package.json
cat > "$project_name/package-dep.json" << 'EOF'
{
    "name": "dashboard-sales",
    "version": "1.0.0",
    "description": "",
    "main": "index.js",
    "scripts": {
        "test": "echo \"Error: no test specified\" && exit 1"
    },
    "keywords": [],
    "author": "",
    "license": "ISC",
    "dependencies": {
        "boxicons": "^2.0.9",
        "dropzone": "^6.0.0-beta.2",
        "sweetalert2": "^11.7.12"
    }
}
EOF
# /admon
# .htaccess
cat > "$project_name/admon-$project_name/.htaccess" << 'EOF'
# | Cross-origin images |
<IfModule mod_setenvif.c>
    <IfModule mod_headers.c>
        <FilesMatch "\.(bmp|cur|gif|ico|jpe?g|png|svgz?|webp)$">
            SetEnvIf Origin ":" IS_CORS
            Header set Access-Control-Allow-Origin "*" env=IS_CORS
        </FilesMatch>
    </IfModule>
</IfModule>


# | Cross-origin |
Header set Access-Control-Allow-Origin "*"


# | Error 404 |
ErrorDocument 404 /404.php


# | Force IE to render pages |
<IfModule mod_headers.c>
    Header set X-UA-Compatible "IE=edge"
    <FilesMatch "\.(appcache|crx|css|eot|gif|htc|ico|jpe?g|js|m4a|m4v|manifest|mp4|oex|oga|ogg|ogv|otf|pdf|png|safariextz|svgz?|ttf|vcf|webapp|webm|webp|woff|xml|xpi)$">
        Header unset X-UA-Compatible
    </FilesMatch>
</IfModule>


# | UTF-8 Encoding |
AddDefaultCharset utf-8
# Force UTF-8 for certain file formats.
<IfModule mod_mime.c>
    AddCharset utf-8 .atom .css .js .json .rss .vtt .webapp .xml
</IfModule>


### --- NUEVA CONFIGURACIÓN DE SESIONES PHP (AGREGADA AQUÍ) --- ###
# <IfModule php_module>
    # php_value session.gc_maxlifetime 3600     # Sesiones expiran en 1 hora
    # php_value session.gc_probability 1        # 1% de probabilidad de limpieza
    # php_value session.gc_divisor 100          # Cada 100 peticiones
# </IfModule>
### --- FIN DE NUEVA CONFIGURACIÓN --- ###


# | Web performance |
<IfModule mod_deflate.c>
    <IfModule mod_setenvif.c>
        <IfModule mod_headers.c>
            SetEnvIfNoCase ^(Accept-EncodXng|X-cept-Encoding|X{15}|~{15}|-{15})$ ^((gzip|deflate)\s*,?\s*)+|[X~-]{4,13}$ HAVE_Accept-Encoding
            RequestHeader append Accept-Encoding "gzip,deflate" env=HAVE_Accept-Encoding
        </IfModule>
    </IfModule>

    <IfModule mod_filter.c>
        AddOutputFilterByType DEFLATE application/atom+xml \
                                      application/javascript \
                                      application/json \
                                      application/rss+xml \
                                      application/vnd.ms-fontobject \
                                      application/x-font-ttf \
                                      application/x-web-app-manifest+json \
                                      application/xhtml+xml \
                                      application/xml \
                                      font/opentype \
                                      image/svg+xml \
                                      image/x-icon \
                                      text/css \
                                      text/html \
                                      text/plain \
                                      text/x-component \
                                      text/xml
    </IfModule>
</IfModule>


# | Forcing HTTPS |
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</IfModule>


# | Cross-origin images |
<IfModule mod_rewrite.c>
    Options +FollowSymlinks
    Options +SymLinksIfOwnerMatch
    RewriteEngine On
    # RewriteBase /dashboard-sales/

    RewriteRule ^([-a-zA-Z0-9ñÑ_/]+)$ index.php?ruta=$1
</IfModule>
EOF

# manifest.json
cat > "$project_name/admon-$project_name/public/img/icons/manifest.json" << 'EOF'
{
    "name": "Hawaiian Frogs | Admin",
    "short_name": "HawaiianFrogs Admin",
    "description":"HAWAIIAN FROGS te ofrece fresas con crema, elotes, raspados, platillos como waffles, entre otros mas, visítanos | HAWAIIAN FROGS  ciudad juárez",
    "start_url": "https://hawaiianfrogs.com.mx/admon-hawaiin-frogs/",
    "theme_color": "#43b544",
    "background_color": "#09135A",
    "display": "standalone",
    "orientation":"portrait",
    "icons": [
        {
            "src": "/public/img/icons/android/android-icon-36x36.png",
            "sizes": "36x36",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-48x48.png",
            "sizes": "48x48",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-72x72.png",
            "sizes": "72x72",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-96x96.png",
            "sizes": "96x96",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-144x144.png",
            "sizes": "144x144",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-192x192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "/public/img/icons/android/android-icon-512x512.png",
            "sizes": "512x512",
            "type": "image/png"
        }
    ]
}
EOF

# sw.js
cat > "$project_name/admon-$project_name/public/img/icons/manifest.json" << 'EOF'
self.addEventListener( 'fetch', event => {
  // console.log( event );
})
EOF

# package.json
cat > "$project_name/admon-$project_name/package-dep.json" << 'EOF'
{
    "name": "dashboard-sales",
    "version": "1.0.0",
    "description": "",
    "main": "index.js",
    "scripts": {
        "test": "echo \"Error: no test specified\" && exit 1"
    },
    "keywords": [],
    "author": "",
    "license": "ISC",
    "dependencies": {
        "boxicons": "^2.0.9",
        "dropzone": "^6.0.0-beta.2",
        "sweetalert2": "^11.7.12"
    }
}
EOF

# index
cat > "$project_name/admon-$project_name/index.php" << 'EOF'
<?php
require __DIR__.'/core/init.php';

//--- Enable SESSION and set TIMEZONE
new Config( treu, 'America/Chihuahua' );

$lang = $GLOBALS['config']['lang'] ?? 'es';
$routes = new Routes( $lang );
$thumb = new Thumb();

//--- Config class Layout to use
$layout = new Layout( $lang, [ $routes->getRouteFrontend(), $routes->getRouteBackend] );

//--- Include file router
include __DIR__.'/app/router.php';
?>
EOF

#--- Router
cat > "$project_name/admon-$project_name/app/router.php" << 'EOF'
<?php
class Router {
    // Routes config
    private static $routes [
        // Routes simples (lev1)
        '1' => [
            'name-simple-page' => [
                'file' => './app/views/pages/name-simple-page.php',
                'db_check' => false
            ],
            // Add more routes here...
        ],

        // Routes to categories (lev2)
        '2' => [
            'name-catergory-page' => [
                'file' => './app/views/pages/name-category-page.php',
                'db_check' => [
                    'table' => 'table-category'
                    'field' => 'url'
                ]
            ],
            // Add more routes here...
        ],

        // Routes to single items (lev3)
        '3' => [
            'name-individual-page' => [
                'file' => './app/views/pages/name-individual-page.php',
                'db_check' => [
                    'table' => ['table-individual', 'table-category'],
                    'field' => ['url1', 'url2']
                ]
            ],
            // Add more routes here...
        ]
    ];

    public static funcion handleRequest() {
        // Showing homepage
        if (!isset($_GET[ 'route' ])) {
            require './app/views/pages/index.view.php';
            return;
        }

        // Routes processing
        $route = explode('/', $_GET['route']);
        $route = array_filter($route); // Delete empty elements
        $level = count($route);

        // Routing 
        if (!isset(self::$routes[$level])) {
            self::show404();
            return;
        }

        $main_route = strtolower($route[0]);

        if (!isset(self::$routes[$level][$main_route])) {
            self::show404();
            return;
        }

        $route_config = self::$routes[$level][$main_route];

        // Verify db if is necesary
        if ($route_config['db_check'] !== false) {
            if (!self::checkDatabase($route, $route_config['db_check'])) {
                self::show404();
                return;
            }
        }

        require $route_config['file'];
    }

    private static function checkDatabase($route, $config) {
        if ($route == 2) {
            $result = Queries::select($config['table'], $config['field'], $route[1]);
            return count($result) > 0;
        }
        else if ($route === 3){
            $result = Queries::select($config['table'][0], $config['field'][0], $route[2]);
            $result = Queries::select($config['table'][1], $config['field'][1], $route[1]);
            $return (count($result) > 0 && count($result2) > 0);
        }
        return false;
    }

    private static function show404() {
        header('HTTP/1.0 404 Not Found');
        require './app/views/pages/404.php';
    }

}

// Use class
Router()handleRequest();
?>
EOF

# index
cat > "$project_name/admon-$project_name/app/views/pages/index.view.php" << 'EOF'
<?php
EOF

#--- Show spinner and make delay
(sleep 2) &
spinner $!

#--- Successful created and show tree directory
tree "$project_name"
echo "Project: '$project_name' created successful ✅"
echo "Directory structure above 🔼"
echo ""
echo "Change to the project directory with:"
echo "  /> cd $project_name"
echo "Recommendation: Rename <package-dep.json> to <package.json> and install packages"
echo "(boxicons, dropzone, sweetalert2)"
echo "  /> npm install"
echo "Recomendation: Init git repo to track project changes"
echo "  /> git init"
