require "#{File.dirname(__FILE__)}/../test_helper"

class LocaliteControllerTest < ActionController::TestCase
  attr :response

  def body
    response.body
  end
  
  # Replace this with your real tests.
  def test_index_en
    get :index
    
    assert body.index("This is hypertext! (as HTML)")
    assert body.index("What I always wanted to tell you...")
    
    assert body.index("format:html")
    assert body.index("string:error")
    assert body.index("locale:en")
  end

  def test_index_de
    get :index, :lang => "de"

    assert body.index("Das ist Hypertext! (in HTML)")
    assert body.index("Was ich schon immer mal loswerden wollte...")
    
    assert body.index("format:html")
    assert body.index("string:error")
    assert body.index("locale:de")
  end

  def test_index_unknown
    get :index, :lang => "un" # must be 2 chars!
  
    assert body.index("format:html")
    assert body.index("string:error")
    assert body.index("locale:en")
  end

  def test_auto
    get :auto
  
    assert body.index("format:html")
    assert body.index("string:error")
    assert body.index("locale:de")
  end

  def test_template_selection_english
    get :template
  
    assert body.index("english")
  end

  def test_template_selection_de
    get :template, :lang => "de"
  
    assert body.index("deutsch")
  end
end
